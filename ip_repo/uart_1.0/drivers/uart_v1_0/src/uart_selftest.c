
/***************************** Include Files *******************************/
#include "uart.h"
#include "xparameters.h"
#include "stdio.h"
#include "xil_io.h"

/************************** Constant Definitions ***************************/
#define READ_WRITE_MUL_FACTOR 0x10

/************************** Function Definitions ***************************/
/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the UARTinstance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus UART_Reg_SelfTest(void * baseaddr_p)
{
	u32 baseaddr;
	int write_loop_index;
	int read_loop_index;
	int Index;

	baseaddr = (u32) baseaddr_p;

	xil_printf("******************************\n\r");
	xil_printf("* User Peripheral Self Test\n\r");
	xil_printf("******************************\n\n\r");

	/*
	 * Write to user logic slave module register(s) and read back
	 */
	xil_printf("User logic slave module test...\n\r");

	/* SR/RDR are read-only and TDR write starts a transmit,
	 * so only CR (0x0C) is used for the plain write/read check. */
	for (write_loop_index = 0 ; write_loop_index < 4; write_loop_index++) {
	  u32 v = (write_loop_index+1)*READ_WRITE_MUL_FACTOR;
	  UART_mWriteReg (baseaddr, UART_CR_OFFSET, v);
	  if ( UART_mReadReg (baseaddr, UART_CR_OFFSET) != v ) {
	    xil_printf ("Error reading CR at address %x\n\r", (int)baseaddr + UART_CR_OFFSET);
	    UART_mWriteReg (baseaddr, UART_CR_OFFSET, 0);
	    return XST_FAILURE;
	  }
	}
	UART_mWriteReg (baseaddr, UART_CR_OFFSET, 0);   /* rx_ie off */
	(void)read_loop_index; (void)Index;

	xil_printf("   - slave register write/read passed\n\n\r");

	return XST_SUCCESS;
}
