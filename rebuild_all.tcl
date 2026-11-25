# ------------------------------------------------------------
# One-shot: refresh IP -> fix uart_rx -> bitstream -> export xsa
# Usage (Vivado Tcl Console, project 20261124_MicroBlaze_GPIO_UART open):
#   source D:/SoC/AXI/RTL/20261124_MicroBlaze_GPIO_UART/rebuild_all.tcl
# ------------------------------------------------------------
set prj D:/SoC/AXI/RTL/20261124_MicroBlaze_GPIO_UART

# 1) refresh IP catalog (driver fix in ip_repo/uart_1.0)
update_ip_catalog -rebuild -scan_changes
open_bd_design $prj/20261124_MicroBlaze_GPIO_UART.srcs/sources_1/bd/design_1/design_1.bd
set ips [get_ips -quiet -filter {IPDEF =~ user.org:user:uart:*}]
if {[llength $ips]} { catch {upgrade_ip $ips} msg; puts "UPGRADE: $msg" }

# 2) uart_rx port, remove tx->rx loop, In2 <- btn interrupt (validate/save/wrapper inside)
source $prj/fix_uart_rx.tcl

# 3) bitstream
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
puts "IMPL STATUS: [get_property STATUS [get_runs impl_1]]"

# 4) export hardware (with bitstream)
catch {close_design}
write_hw_platform -fixed -include_bit -force -file $prj/xsa/design_1_wrapper.xsa
puts "REBUILD_ALL_DONE"
