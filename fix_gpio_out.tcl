# ------------------------------------------------------------
# LED / FND GPIO -> All Outputs, then bitstream + export xsa
#   axi_gpio_1 (led)              : 16bit output  -> led_tri_o
#   axi_gpio_0 ch1 (fnd_font)     : 8bit  output  -> fnd_font_tri_o
#   axi_gpio_0 ch2 (fnd_com)      : 4bit  output  -> fnd_com_tri_o
# Usage (Vivado Tcl Console):
#   source D:/SoC/AXI/RTL/20261124_MicroBlaze_GPIO_UART/fix_gpio_out.tcl
# ------------------------------------------------------------
set prj D:/SoC/AXI/RTL/20261124_MicroBlaze_GPIO_UART
open_bd_design $prj/20261124_MicroBlaze_GPIO_UART.srcs/sources_1/bd/design_1/design_1.bd

set_property -dict [list CONFIG.C_ALL_INPUTS {0} CONFIG.C_ALL_OUTPUTS {1} \
                         CONFIG.C_GPIO_WIDTH {16}] [get_bd_cells axi_gpio_1]

set_property -dict [list CONFIG.C_ALL_INPUTS {0}   CONFIG.C_ALL_OUTPUTS {1}   CONFIG.C_GPIO_WIDTH {8} \
                         CONFIG.C_ALL_INPUTS_2 {0} CONFIG.C_ALL_OUTPUTS_2 {1} CONFIG.C_GPIO2_WIDTH {4}] \
                   [get_bd_cells axi_gpio_0]

validate_bd_design
save_bd_design
make_wrapper -files [get_files design_1.bd] -top -force

# bitstream
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
puts "IMPL STATUS: [get_property STATUS [get_runs impl_1]]"

# export hardware (with bitstream)
catch {close_design}
write_hw_platform -fixed -include_bit -force -file $prj/xsa/design_1_wrapper.xsa
puts "FIX_GPIO_OUT_DONE"
