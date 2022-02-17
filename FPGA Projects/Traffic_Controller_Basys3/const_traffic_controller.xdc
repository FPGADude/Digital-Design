# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]
 
##Buttons
set_property PACKAGE_PIN U18 	 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]

##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 	 [get_ports {main_st[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {main_st[2]}]
##Sch name = JB2
set_property PACKAGE_PIN A16 	 [get_ports {main_st[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {main_st[1]}]
##Sch name = JB3
set_property PACKAGE_PIN B15 	 [get_ports {main_st[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {main_st[0]}]

##Pmod Header JC
##Sch name = JC1
set_property PACKAGE_PIN K17 	 [get_ports {cross_st[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {cross_st[2]}]
##Sch name = JC2
set_property PACKAGE_PIN M18 	 [get_ports {cross_st[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {cross_st[1]}]
##Sch name = JC3
set_property PACKAGE_PIN N17 	 [get_ports {cross_st[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {cross_st[0]}]