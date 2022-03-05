# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]

# LEDs
set_property PACKAGE_PIN U16 	 [get_ports {o_bin[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {o_bin[0]}]
set_property PACKAGE_PIN E19 	 [get_ports {o_bin[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {o_bin[1]}]
set_property PACKAGE_PIN U19 	 [get_ports {o_bin[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {o_bin[2]}]

set_property PACKAGE_PIN W18 	 [get_ports {o_gray_code[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {o_gray_code[0]}]
set_property PACKAGE_PIN U15 	 [get_ports {o_gray_code[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {o_gray_code[1]}]
set_property PACKAGE_PIN U14 	 [get_ports {o_gray_code[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {o_gray_code[2]}]

##Buttons
set_property PACKAGE_PIN U18 	 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]