/*
 * my_uart.h
 *
 *  Created on: 2026. 11. 24.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_MY_UART_MY_UART_H_
#define SRC_DRIVER_MY_UART_MY_UART_H_

#include "xparameters.h"
#include <stdint.h>

typedef struct {
	volatile uint32_t SR;	// 0x00 [0] tx_busy, [1] rx_flag
	volatile uint32_t TDR;	// 0x04 [7:0] write -> transmit
	volatile uint32_t RDR;	// 0x08 [7:0] received data
	volatile uint32_t CR;	// 0x0C [0] rx_ie
}UART_TypeDef;

#define UART_BASEADDR	XPAR_UART_0_S00_AXI_BASEADDR
#define UART0			((UART_TypeDef *)UART_BASEADDR)

#define UART_SR_TX_BUSY	(1<<0)
#define UART_SR_RX_FLAG	(1<<1)

void UART_Transmit(UART_TypeDef *uart, uint8_t data);
uint8_t UART_Receive(UART_TypeDef *uart);
uint8_t UART_RxAvalable(UART_TypeDef *uart);


#endif /* SRC_DRIVER_MY_UART_MY_UART_H_ */
