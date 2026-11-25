/*
 * my_uart.c
 *
 *  Created on: 2026. 11. 24.
 *      Author: kccistc
 */

#include "my_uart.h"

// SR.tx_busy 가 0 이 될 때까지 기다렸다가 TDR 에 쓰기 -> 송신 시작
void UART_Transmit(UART_TypeDef *uart, uint8_t data)
{
	while (uart->SR & UART_SR_TX_BUSY);
	uart->TDR = data;
}

// SR.rx_flag 가 1 이 될 때까지 기다렸다가 RDR 읽기 (읽으면 rx_flag 자동 0)
uint8_t UART_Receive(UART_TypeDef *uart)
{
	while (!(uart->SR & UART_SR_RX_FLAG));
	return (uint8_t)uart->RDR;
}

// 받아 둔 데이터가 있으면 1
uint8_t UART_RxAvalable(UART_TypeDef *uart)
{
	return (uart->SR & UART_SR_RX_FLAG) ? 1 : 0;
}
