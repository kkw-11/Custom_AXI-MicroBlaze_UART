`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: uart
// Description: UART TX / RX (8N1)
//   TX FSM : IDLE -> START -> D0 -> D1 -> ... -> D7 -> STOP -> IDLE
//   RX FSM : IDLE -> START(half bit check) -> DATA(x8) -> STOP -> IDLE
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// Top : TX + RX
//==============================================================================
module uart #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    // TX internal
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_busy,
    output wire       tx_done,
    // RX internal
    output wire [7:0] rx_data,
    output wire       rx_done,
    // external port
    output wire       tx,
    input  wire       rx
);

    uart_tx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) U_UART_TX (
        .clk     (clk),
        .rst_n   (rst_n),
        .tx_data (tx_data),
        .tx_start(tx_start),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        .tx      (tx)
    );

    uart_rx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) U_UART_RX (
        .clk    (clk),
        .rst_n  (rst_n),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx     (rx)
    );

endmodule


//==============================================================================
// UART TX
//==============================================================================
module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    // internal signal
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_busy,
    output wire       tx_done,
    // external port
    output wire       tx
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam S_IDLE = 4'd0, S_START = 4'd1,
               S_D0 = 4'd2, S_D1 = 4'd3, S_D2 = 4'd4, S_D3 = 4'd5,
               S_D4 = 4'd6, S_D5 = 4'd7, S_D6 = 4'd8, S_D7 = 4'd9,
               S_STOP = 4'd10;

    reg tx_r, tx_busy_r, tx_done_r;
    reg [3:0] state;  // 11 states (0~10) -> 4bit 필요
    reg [$clog2(CLKS_PER_BIT):0] clk_cnt;
    reg [7:0] tx_data_r;

    assign tx      = tx_r;
    assign tx_busy = tx_busy_r;
    assign tx_done = tx_done_r;

    // 1 bit 시간(CLKS_PER_BIT clk) 경과
    wire bit_end = (clk_cnt == CLKS_PER_BIT - 1);

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            tx_r      <= 1'b1;
            tx_busy_r <= 1'b0;
            tx_done_r <= 1'b0;
            tx_data_r <= 8'd0;
        end else begin
            tx_done_r <= 1'b0;  // 1clk pulse

            // bit 카운터 : IDLE 이외 상태에서 1 bit 시간 카운트
            if (state == S_IDLE || bit_end) clk_cnt <= 0;
            else                            clk_cnt <= clk_cnt + 1;

            case (state)
                S_IDLE: begin
                    tx_r      <= 1'b1;
                    tx_busy_r <= 1'b0;
                    if (tx_start) begin          // tx_start / tx_busy=1
                        tx_data_r <= tx_data;
                        tx_busy_r <= 1'b1;
                        state     <= S_START;
                    end
                end
                S_START: begin
                    tx_r <= 1'b0;
                    if (bit_end) state <= S_D0;  // 1bit 시간 경과
                end
                S_D0: begin
                    tx_r <= tx_data_r[0];
                    if (bit_end) state <= S_D1;
                end
                S_D1: begin
                    tx_r <= tx_data_r[1];
                    if (bit_end) state <= S_D2;
                end
                S_D2: begin
                    tx_r <= tx_data_r[2];
                    if (bit_end) state <= S_D3;
                end
                S_D3: begin
                    tx_r <= tx_data_r[3];
                    if (bit_end) state <= S_D4;
                end
                S_D4: begin
                    tx_r <= tx_data_r[4];
                    if (bit_end) state <= S_D5;
                end
                S_D5: begin
                    tx_r <= tx_data_r[5];
                    if (bit_end) state <= S_D6;
                end
                S_D6: begin
                    tx_r <= tx_data_r[6];
                    if (bit_end) state <= S_D7;
                end
                S_D7: begin
                    tx_r <= tx_data_r[7];
                    if (bit_end) state <= S_STOP;
                end
                S_STOP: begin
                    tx_r <= 1'b1;
                    if (bit_end) begin           // 1bit 시간 / tx_done=1
                        tx_done_r <= 1'b1;
                        tx_busy_r <= 1'b0;
                        state     <= S_IDLE;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule


//==============================================================================
// UART RX
//==============================================================================
module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    // internal signal
    output wire [7:0] rx_data,
    output wire       rx_done,
    // external port
    input  wire       rx
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT     = CLKS_PER_BIT / 2;

    localparam S_IDLE = 2'd0, S_START = 2'd1, S_DATA = 2'd2, S_STOP = 2'd3;

    reg [1:0] state;
    reg [$clog2(CLKS_PER_BIT):0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] rx_shift;
    reg [7:0] rx_data_r;
    reg rx_done_r;

    // 비동기 입력 rx : 2-FF synchronizer (idle = 1)
    reg rx_sync1, rx_sync2;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    assign rx_data = rx_data_r;
    assign rx_done = rx_done_r;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            rx_shift  <= 8'd0;
            rx_data_r <= 8'd0;
            rx_done_r <= 1'b0;
        end else begin
            rx_done_r <= 1'b0;  // 1clk pulse

            case (state)
                S_IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_sync2 == 1'b0) state <= S_START;  // falling edge 검출
                end

                // start bit 중앙(half bit)에서 다시 확인 -> glitch 제거
                S_START: begin
                    if (clk_cnt == HALF_BIT - 1) begin
                        clk_cnt <= 0;
                        if (rx_sync2 == 1'b0) state <= S_DATA;
                        else                  state <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                // 이후 1bit 간격마다 각 bit 중앙에서 샘플링 (LSB first)
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt  <= 0;
                        rx_shift <= {rx_sync2, rx_shift[7:1]};
                        if (bit_idx == 3'd7) state   <= S_STOP;
                        else                 bit_idx <= bit_idx + 1;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                // stop bit 중앙에서 '1' 확인 후 데이터 출력
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (rx_sync2 == 1'b1) begin
                            rx_data_r <= rx_shift;
                            rx_done_r <= 1'b1;
                        end
                        state <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
