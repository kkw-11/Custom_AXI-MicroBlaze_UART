# Packaged IP has C_BASEADDR / C_HIGHADDR (not C_S00_AXI_BASEADDR),
# so emit XPAR_<INST>_S00_AXI_BASEADDR from C_BASEADDR.
proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "uart" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR"

	set fh [::hsi::utils::open_include_file "xparameters.h"]
	foreach periph [::hsi::utils::get_common_driver_ips $drv_handle] {
		set name [string toupper [common::get_property NAME $periph]]
		set base [common::get_property CONFIG.C_BASEADDR $periph]
		set high [common::get_property CONFIG.C_HIGHADDR $periph]
		puts $fh "#define XPAR_${name}_S00_AXI_BASEADDR $base"
		puts $fh "#define XPAR_${name}_S00_AXI_HIGHADDR $high"
	}
	puts $fh ""
	close $fh
}
