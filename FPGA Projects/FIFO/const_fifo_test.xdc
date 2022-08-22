# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]
 
# Switches
set_property PACKAGE_PIN V17 	 [get_ports {sw[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 	 [get_ports {sw[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 	 [get_ports {sw[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]

# LEDs
set_property PACKAGE_PIN U16 	 [get_ports {empty}]					
set_property IOSTANDARD LVCMOS33 [get_ports {empty}]

set_property PACKAGE_PIN U15 	 [get_ports {data_out[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[0]}]
set_property PACKAGE_PIN U14 	 [get_ports {data_out[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[1]}]
set_property PACKAGE_PIN V14 	 [get_ports {data_out[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[2]}]

set_property PACKAGE_PIN L1 	 [get_ports {full}]					
set_property IOSTANDARD LVCMOS33 [get_ports {full}]

##Buttons
## btnC
set_property PACKAGE_PIN U18 	 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]
## btnU
set_property PACKAGE_PIN T18 	 [get_ports wr]						
set_property IOSTANDARD LVCMOS33 [get_ports wr]
## btnD
set_property PACKAGE_PIN U17 	 [get_ports rd]						
set_property IOSTANDARD LVCMOS33 [get_ports rd]