/*
 * main.c
 *
 *  Created on: 2026. 11. 24.
 *      Author: kccistc
 */

#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h"
#include "xgpio.h"
#include <stdint.h>
#include "driver/my_uart/my_uart.h"

#define GPIO_FND_DEV_ID XPAR_AXI_GPIO_0_DEVICE_ID
#define GPIO_LED_DEV_ID XPAR_AXI_GPIO_1_DEVICE_ID
#define GPIO_BTN_DEV_ID XPAR_AXI_GPIO_2_DEVICE_ID
#define GPIO_SW_DEV_ID XPAR_AXI_GPIO_3_DEVICE_ID

XGpio GPIO_LED;
XGpio GPIO_SW;
XGpio GPIO_BTN;


int main(void)
{
	uint16_t sw_data;

	// 1. AXI GPIO 초기화
	XGpio_Initialize(&GPIO_LED, GPIO_LED_DEV_ID);
	XGpio_Initialize(&GPIO_SW, GPIO_SW_DEV_ID);

	// 2. 입출력 방향 설정
	XGpio_SetDataDirection(&GPIO_LED, 1, 0x00000); //0:output, 1:input mode
	XGpio_SetDataDirection(&GPIO_SW, 1, 0xffff); //0:output, 1:input mode

	uint8_t tx_data = 'a';
	uint8_t rx_data;
	xil_printf("start, UART0 = 0x%08x\r\n", UART_BASEADDR);
	while (1)
	{
		//		sw_data = XGpio_DiscreteRead(&GPIO_SW, 1);
		//		XGpio_DiscreteWrite(&GPIO_LED, 1, sw_data);
		//XGpio_DiscreteWrite(&GPIO_LED, 1, 0xffff);
		//sleep(1);
		//usleep(200000);
		//XGpio_DiscreteWrite(&GPIO_LED, 1, 0x0000);
		//sleep(1);
		//usleep(200000);

//		while (UART0->SR & (1<<0));
//		UART0->TDR = tx_data;
		UART_Transmit(UART0, tx_data);
		if (tx_data == 'z') tx_data = 'a';
		else tx_data++;

		sleep(1);

		if (UART_RxAvalable(UART0)) {
			rx_data = UART_Receive(UART0);
			xil_printf("received : %c \n", rx_data);
		}
	}

	return 0;
}
