# ------------------------------------------------------------
# Match instructor design:
#   uart_0/tx -> uart_tx (JB1, A14)
#   uart_0/rx <- uart_rx (JB2, A16)   (no internal tx->rx loop)
#   concat In2 <- axi_gpio_2 (btn) interrupt  (was wrongly uart_0/tx)
# Usage (Vivado Tcl Console):
#   source D:/SoC/AXI/RTL/20261124_MicroBlaze_GPIO_UART/fix_uart_rx.tcl
# ------------------------------------------------------------

# 1) remove current tx net (tx -> uart_tx, rx, concat/In2)
set n [get_bd_nets -quiet -of_objects [get_bd_pins uart_0/tx]]
if {[llength $n]} { delete_bd_objs $n }
set n [get_bd_nets -quiet -of_objects [get_bd_pins uart_0/rx]]
if {[llength $n]} { delete_bd_objs $n }

# 2) tx -> uart_tx
if {[llength [get_bd_ports -quiet uart_tx]] == 0} { create_bd_port -dir O uart_tx }
connect_bd_net [get_bd_pins uart_0/tx] [get_bd_ports uart_tx]

# 3) uart_rx -> rx
if {[llength [get_bd_ports -quiet uart_rx]] == 0} { create_bd_port -dir I uart_rx }
connect_bd_net [get_bd_ports uart_rx] [get_bd_pins uart_0/rx]

# 4) concat In2 <- axi_gpio_2 interrupt (if not connected yet)
set irq [get_bd_pins -quiet axi_gpio_2/ip2intc_irpt]
set in2 [get_bd_pins -quiet microblaze_0_xlconcat/In2]
if {[llength $irq] && [llength $in2] && [llength [get_bd_nets -quiet -of_objects $in2]] == 0} {
    connect_bd_net $irq $in2
}

regenerate_bd_layout
validate_bd_design
save_bd_design
make_wrapper -files [get_files design_1.bd] -top -force
puts "FIX_UART_RX_DONE"
