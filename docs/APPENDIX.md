# 상세 자료 (Appendix)

> [README](../README.md)의 보충 자료.
> 하드웨어 전공이 아닌 사람도 읽을 수 있게 **쉬운 설명 → 용어 → 전체 표 → 재현 방법** 순서로 정리함.

---

## A. 이 프로젝트를 쉽게 설명하면

- **한 줄 요약**: FPGA 칩 안에 작은 컴퓨터(CPU)를 만들고, 직접 설계한 "통신 부품"을 붙여서 프로그램으로 글자를 주고받게 함
- **비유**
  - FPGA = 레고판. 회로를 마음대로 조립하고 다시 바꿀 수 있는 칩
  - MicroBlaze = 레고판 위에 조립한 CPU
  - AXI 버스 = CPU와 부품들을 잇는 도로. 부품마다 **집 주소**가 있음
  - 커스텀 UART IP = 직접 만든 "우체국". CPU가 주소로 편지(글자)를 맡기면 선 한 가닥으로 1비트씩 보냄
  - 레지스터 = 우체국 창구. "지금 바쁜가요?(SR)", "보낼 편지(TDR)", "받은 편지(RDR)", "설정(CR)"
- **무엇을 확인했나**
  - 보낸 선(JB1)과 받는 선(JB2)을 전선 하나로 이어서, 보낸 글자가 그대로 돌아오는지 확인 (루프백)
  - 'a'부터 'z'까지 1초마다 보내고 돌아온 글자를 PC 화면에 출력 → 정상
- **왜 의미가 있나**
  - 회로 설계(Verilog)와 프로그램(C)이 **레지스터 주소라는 약속**으로 연결되는 전 과정을 직접 구현함
  - 상용 칩(STM32 등)의 주변장치도 같은 구조. 이번 결과물은 그 구조를 직접 만든 것

---

## B. 용어집

| 용어 | 뜻 |
| --- | --- |
| FPGA | 내부 회로를 프로그램으로 바꿀 수 있는 칩. 이번 보드는 Xilinx Artix-7 |
| Basys3 | FPGA 교육용 보드 (Digilent). 스위치, LED, 7세그먼트, 버튼, Pmod 커넥터 포함 |
| MicroBlaze | FPGA 안에 회로로 만드는 32비트 CPU (Xilinx 제공) |
| UART | 선 2가닥(tx, rx)으로 1비트씩 보내는 가장 단순한 시리얼 통신 |
| baud rate | UART 속도. 115200 = 초당 115,200비트 |
| AXI4-Lite | ARM이 정한 버스 규격 중 간단한 버전. 주소 읽기/쓰기만 지원 |
| 슬레이브 IP | 버스에서 명령을 받는 쪽 부품. 이번 UART IP가 해당 |
| IP | 재사용 가능한 회로 블록 (Intellectual Property) |
| IP 패키징 | 만든 회로를 IP Catalog에 등록해 다른 프로젝트에서 꺼내 쓰게 만드는 작업 |
| 레지스터 | 부품 안의 32비트 저장 칸. CPU가 주소로 읽고 씀 |
| 베이스 주소 | 부품의 시작 주소. 레지스터 주소 = 베이스 + 오프셋 |
| Memory-mapped I/O | 주변장치를 메모리처럼 주소로 다루는 방식 |
| 인터럽트 | 부품이 CPU에게 "일 생겼다"고 알리는 신호 |
| 블록도 (Block Design) | Vivado에서 IP를 그림으로 연결해 시스템을 만드는 화면 |
| XDC | 회로의 포트 이름을 보드의 실제 핀 번호에 연결하는 설정 파일 |
| 비트스트림 (.bit) | FPGA에 실제로 올리는 회로 파일 |
| .xsa | 블록도 정보 + 비트스트림 + 드라이버를 묶은 파일. Vivado → Vitis로 전달 |
| BSP / 플랫폼 | Vitis가 .xsa로 만든 기본 소프트웨어 (드라이버, `xparameters.h`) |
| xparameters.h | 각 부품의 주소가 `#define`으로 정리된 헤더 |
| 루프백 | 보낸 신호를 자기 자신이 다시 받게 연결해 송수신을 한 번에 확인하는 시험 |
| Pmod | Digilent 확장 커넥터 규격. JB = 보드의 Pmod 커넥터 중 하나 |
| volatile | C에서 "이 값은 하드웨어가 바꿀 수 있으니 매번 실제로 읽으라"는 표시 |

---

## C. 하드웨어 구성 전체

| 블록 | 역할 | 베이스 주소 |
| --- | --- | --- |
| microblaze_0 | 32비트 CPU, C 코드 실행 | - |
| local_memory (BRAM) | 프로그램과 데이터 저장, 128KB | 0x0000_0000 |
| axi_interconnect | CPU 한 개와 주변장치 여러 개를 잇는 버스 분배기 | - |
| axi_gpio_0 | FND 세그먼트 8비트(ch1), 자리 선택 4비트(ch2) | 0x4000_0000 |
| axi_gpio_1 | LED 16비트 | 0x4001_0000 |
| axi_gpio_2 | 버튼 4비트, 인터럽트 출력 사용 | 0x4002_0000 |
| axi_gpio_3 | 스위치 16비트 | 0x4003_0000 |
| axi_uartlite_0 | Xilinx 기본 UART, PC 콘솔용 (USB, 115200) | 0x4060_0000 |
| microblaze_0_axi_intc | 인터럽트 컨트롤러 (xlconcat으로 입력 3개) | 0x4120_0000 |
| **uart_0** | **직접 만든 AXI4-Lite UART IP** | **0x44A0_0000** |
| clk_wiz / proc_sys_reset | 100MHz 클럭 생성, 리셋 동기화 | - |

- 인터럽트 입력: In0 = uart_0, In1 = axi_uartlite_0, In2 = axi_gpio_2(버튼)

---

## D. 핀 배치 전체 (Basys-3-Master.xdc)

| 포트 | 핀 | 보드 부품 |
| --- | --- | --- |
| sys_clock | W5 | 100MHz 오실레이터 |
| reset | U18 | BTNC (가운데 버튼) |
| usb_uart_rxd / usb_uart_txd | B18 / A18 | USB-UART (PC 콘솔) |
| uart_tx / uart_rx | A14 / A16 | Pmod JB1 / JB2 (커스텀 UART) |
| btn_tri_i[3:0] | T18, W19, T17, U17 | BTNU, BTNL, BTNR, BTND |
| sw_tri_io[15:0] | V17 … R2 | 슬라이드 스위치 16개 |
| led_tri_o[15:0] | U16 … L1 | LED 16개 |
| fnd_font_tri_o[7:0] | W7, W6, U8, V8, U5, V5, U7, V7 | 7세그먼트 a~g, dp |
| fnd_com_tri_o[3:0] | U2, U4, V4, W4 | 7세그먼트 자리 4개 |

- 포트 이름은 래퍼(`design_1_wrapper`)의 이름과 정확히 같아야 함
- 보드에 없는 핀을 포트로 만들면 배치 단계에서 에러 (아래 E 참고)

---

## E. 트러블슈팅 전체 목록

| # | 증상 | 원인 | 해결 |
| --- | --- | --- | --- |
| 1 | Place 30-58: 핀이 없는 포트 | btn / fnd_com GPIO가 16비트인데 보드에는 4개뿐 | GPIO 폭을 4비트로 축소 |
| 2 | Vitis 빌드 `mb-ar *.o: Invalid argument` | 윈도우 CMD에서 Makefile 와일드카드 `*.o` 미해석 | 드라이버 Makefile을 `$(wildcard ...)`로 변경 |
| 3 | `xparameters.h` not found, 빨간 X | 2번 실패로 BSP 미생성, 인덱서 갱신 안 됨 | Makefile 수정 후 플랫폼 재빌드 |
| 4 | `write_hw_platform` 실패 | 경로에 `.../xsa`를 글자 그대로 입력 | 전체 경로가 들어간 `rebuild_all.tcl` 사용 |
| 5 | main.c 구조체 컴파일 에러 | 멤버 끝에 `;` 대신 `:` | `;`로 수정, `volatile` 추가 |
| 6 | `UART0 = 0x00000000` (1) | Vitis가 uart_0 추가 전의 예전 xsa 사용 | 새 xsa로 Update Hardware Specification |
| 7 | `UART0 = 0x00000000` (2) | 드라이버 tcl이 `C_S00_AXI_BASEADDR` 검색 (실제 `C_BASEADDR`) | `data/uart.tcl`에서 주소 매크로 직접 생성 |
| 8 | 블록도에서 tx가 rx로 직결 | 자동 연결이 내부 루프를 만듦 | `fix_uart_rx.tcl`로 tx → uart_tx, uart_rx → rx 분리 |
| 9 | LED/FND가 입력으로 설정됨 | GPIO를 All Inputs로 생성 | `fix_gpio_out.tcl` 작성 (미실행) |

---

## F. 진행 과정 전체

1. **UART IP 패키징**: AXI4-Lite 템플릿에 SR/TDR/RDR/CR 구현, uart.v 연결 → `ip_repo/uart_1.0`으로 패키징 (드라이버 폴더 포함)
2. **블록도 구성**: 새 프로젝트에 MicroBlaze, GPIO 4개, Uartlite, 인터럽트 컨트롤러 배치, IP Catalog에서 uart_0 추가
3. **uart_0 배선**: tx → `uart_tx`, rx ← `uart_rx`, intr → 인터럽트 In0, 주소 0x44A0_0000
4. **XDC 작성**: uart_tx = A14(JB1), uart_rx = A16(JB2), 나머지 포트도 래퍼 이름에 맞춤
5. **비트스트림 + xsa**: 합성 → 구현 → 비트스트림 → `write_hw_platform -include_bit`
6. **Vitis 플랫폼/앱**: xsa로 플랫폼 생성, 버튼 드라이버 XGpio 포팅, my_uart 드라이버 분리
7. **보드 테스트**: PC 콘솔 출력 확인 → JB1–JB2 점퍼 루프백 확인

---

## G. 재현 방법

1. Basys3를 USB로 연결, JB1–JB2를 점퍼선으로 연결
2. Vivado에서 프로젝트 열기 → Tcl Console:
   ```tcl
   source D:/SoC/AXI/RTL/20261124_MicroBlaze_GPIO_UART/rebuild_all.tcl
   ```
   - `REBUILD_ALL_DONE` 출력 확인 → `xsa/design_1_wrapper.xsa` 생성
3. Vitis에서 `vitis_workspace` 열기
   - 플랫폼 `design_1_wrapper` → Update Hardware Specification → 위 xsa 선택 → 플랫폼 Build
   - 앱 `hello_uart` Build → Run As → Launch Hardware
4. 터미널 프로그램(ComPortMaster 등): COM 포트, 115200, 8N1
   - `start, UART0 = 0x44a00000` 후 `received : …`가 1초마다 나오면 성공

---

## H. 스크립트 목록

| 파일 | 하는 일 |
| --- | --- |
| `add_uart.tcl` | 블록도에 uart_0 추가, AXI 자동 연결, uart_tx 포트 생성 |
| `fix_uart_rx.tcl` | tx/rx 배선 분리, uart_rx 포트 생성, 버튼 인터럽트를 In2에 연결 |
| `rebuild_all.tcl` | IP 갱신 → `fix_uart_rx.tcl` → 비트스트림 → xsa export 일괄 실행 |
| `fix_gpio_out.tcl` | LED/FND GPIO를 출력으로 변경 후 비트스트림, xsa export |

---

## I. 기타: 버튼 드라이버 포팅

- 기존 STM32 HAL용 버튼 드라이버를 Xilinx XGpio로 변경
- `button_t { XGpio *GPIOx; uint16_t GPIO_Pin; int prevState; }`
- 핀 읽기: `(XGpio_DiscreteRead(gpio, 1) >> pin) & 1`, 디바운스 5ms
- Basys3 버튼은 누르면 1 (active-high)
- UART 테스트와는 별개 작업이라 README에서는 제외
