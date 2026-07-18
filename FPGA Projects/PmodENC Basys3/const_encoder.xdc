# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]

# LEDs
set_property PACKAGE_PIN U16 	 [get_ports {LED[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 	 [get_ports {LED[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]

##Buttons
set_property PACKAGE_PIN U18 	 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]

#7 segment display
set_property PACKAGE_PIN W7 	 [get_ports {seg[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 	 [get_ports {seg[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 	 [get_ports {seg[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 	 [get_ports {seg[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 	 [get_ports {seg[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 	 [get_ports {seg[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 	 [get_ports {seg[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

set_property PACKAGE_PIN U2 	 [get_ports {an[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 	 [get_ports {an[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 	 [get_ports {an[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 	 [get_ports {an[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

##Pmod Header JB
##Sch name = JB7
set_property PACKAGE_PIN A15 	 [get_ports {JB[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {JB[4]}]
##Sch name = JB8
set_property PACKAGE_PIN A17 	 [get_ports {JB[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {JB[5]}]
##Sch name = JB9
set_property PACKAGE_PIN C15 	 [get_ports {JB[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {JB[6]}]
##Sch name = JB10 
set_property PACKAGE_PIN C16 	 [get_ports {JB[7]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {JB[7]}]