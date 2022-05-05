# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]
	
##Buttons
## btnD
set_property PACKAGE_PIN U17 	 [get_ports play]						
set_property IOSTANDARD LVCMOS33 [get_ports play]

##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 	 [get_ports {speaker}]					
set_property IOSTANDARD LVCMOS33 [get_ports {speaker}]