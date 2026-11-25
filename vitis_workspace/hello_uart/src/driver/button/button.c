/*
 * button.c
 *
 *  Created on: 2026. 10. 16.
 *      Author: rhoblack
 */

#include "button.h"
#include "xparameters.h"
#include "sleep.h"

#define GPIO_BTN_DEV_ID XPAR_AXI_GPIO_2_DEVICE_ID

void button_init(button_t *btn, XGpio *gpiox, uint16_t GPIO_Pin)
{
	btn->GPIOx = gpiox;
	btn->GPIO_Pin = GPIO_Pin;
	btn->prevState = RELEASED;

	XGpio_Initialize(btn->GPIOx, GPIO_BTN_DEV_ID);
	uint32_t dirData = XGpio_GetDataDirection(btn->GPIOx, 1);
	dirData |= (1<<GPIO_Pin);                          // 1:input mode
	XGpio_SetDataDirection(btn->GPIOx, 1, dirData);    // btn -> btn->GPIOx
}

// HAL_GPIO_ReadPin 대신 : 채널1 전체를 읽고 해당 bit 만 꺼냄
static int button_readPin(button_t *btn)
{
	return (XGpio_DiscreteRead(btn->GPIOx, 1) >> btn->GPIO_Pin) & 0x1;
}

button_state_t button_getState(button_t *btn)
{
	int curState;

	curState = (XGpio_DiscreteRead(btn->GPIOx, 1) & (1<<btn->GPIO_Pin)) == 0 ? 0 : 1;
	//curState = HAL_GPIO_ReadPin(btn->GPIOx, btn->GPIO_Pin);

	if ((btn->prevState == RELEASED) && (curState == PUSHED)) {
		btn->prevState = PUSHED;
		//HAL_Delay(5);
		usleep(5000); // debounce code (HAL_Delay(5) -> 5ms)
		return ACT_PUSH;
	}
	else if ((btn->prevState == PUSHED) && (curState == RELEASED)) {
		btn->prevState = RELEASED;
		//HAL_Delay(5); //debounce code
		usleep(5000); // debounce code
		return ACT_RELEASE;
	}
	return NO_ACT;
}
