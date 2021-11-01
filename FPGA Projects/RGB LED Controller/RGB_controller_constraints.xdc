# Design constraints for the RGB controller using BASYS 3 FPGA board

# Switches
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
	
##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 [get_ports {rgb[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {rgb[0]}]
##Sch name = JB2
set_property PACKAGE_PIN A16 [get_ports {rgb[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {rgb[1]}]
##Sch name = JB3
set_property PACKAGE_PIN B15 [get_ports {rgb[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {rgb[2]}]