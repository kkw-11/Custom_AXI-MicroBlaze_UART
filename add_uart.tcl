# ------------------------------------------------------------
# Add custom uart_v1.0 IP to the open block design (design_1)
#   uart_0/S00_AXI -> MicroBlaze AXI (auto connect: clk/reset/interconnect)
#   uart_0/tx      -> external port uart_tx
#   uart_0/rx      <- uart_0/tx  (loop test)
# Usage (Vivado Tcl Console):
#   source D:/SoC/AXI/RTL/20261124_MicroBlaze_GPIO_UART/add_uart.tcl
# ------------------------------------------------------------
update_ip_catalog -rebuild

if {[llength [get_bd_cells -quiet uart_0]] == 0} {
    create_bd_cell -type ip -vlnv user.org:user:uart:1.0 uart_0
}

# AXI slave interface of uart_0 (s00_axi)
set axi_if [get_bd_intf_pins -of_objects [get_bd_cells uart_0] -filter {MODE == Slave}]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config [list Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} \
                  Master {/microblaze_0 (Periph)} Slave "/$axi_if" \
                  ddr_seg {Auto} intc_ip {Auto} master_apm {0}] \
    $axi_if

# tx -> external port uart_tx
if {[llength [get_bd_ports -quiet uart_tx]] == 0} {
    create_bd_port -dir O uart_tx
}
connect_bd_net [get_bd_pins uart_0/tx] [get_bd_ports uart_tx]

# rx <- tx (loop test)
connect_bd_net [get_bd_pins uart_0/tx] [get_bd_pins uart_0/rx]

assign_bd_address -quiet
regenerate_bd_layout
validate_bd_design
save_bd_design
puts "ADD_UART_DONE"
