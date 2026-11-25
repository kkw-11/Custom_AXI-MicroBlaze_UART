/*
 * button.h
 *
 *  Created on: 2026. 10. 16.
 *      Author: rhoblack
 */

#ifndef SRC_DRIVER_BUTTON_BUTTON_H_
#define SRC_DRIVER_BUTTON_BUTTON_H_

#include <stdint.h>
#include "xgpio.h"

typedef enum {
	NO_ACT,
	ACT_PUSH,
	ACT_RELEASE,
}button_state_t;

typedef struct {
	XGpio *GPIOx;        // STM32 GPIO_TypeDef* -> Xilinx XGpio*
	uint16_t GPIO_Pin;   // bit number (0~3)
	int prevState;
}button_t;

// Basys3 버튼은 누르면 1 (STM32 보드와 반대)
enum {RELEASED=0, PUSHED=1};

//void button_init(button_t *btn, GPIO_TypeDef* GPIOx, uint16_t GPIO_Pin);
void button_init(button_t *btn, XGpio *gpiox, uint16_t GPIO_Pin);
button_state_t button_getState(button_t *btn);

#endif /* SRC_DRIVER_BUTTON_BUTTON_H_ */
