# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]

# Switches
set_property PACKAGE_PIN V17 	 [get_ports {SW}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SW}]

# LEDs
set_property PACKAGE_PIN U16 	 [get_ports {LED[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 	 [get_ports {LED[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 	 [get_ports {LED[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 	 [get_ports {LED[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property PACKAGE_PIN W18 	 [get_ports {LED[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN U15 	 [get_ports {LED[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN U14 	 [get_ports {LED[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN V14 	 [get_ports {LED[7]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]

#7 segment display
set_property PACKAGE_PIN W7 	 [get_ports {SEG[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[0]}]
set_property PACKAGE_PIN W6 	 [get_ports {SEG[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[1]}]
set_property PACKAGE_PIN U8 	 [get_ports {SEG[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[2]}]
set_property PACKAGE_PIN V8 	 [get_ports {SEG[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[3]}]
set_property PACKAGE_PIN U5 	 [get_ports {SEG[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[4]}]
set_property PACKAGE_PIN V5 	 [get_ports {SEG[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[5]}]
set_property PACKAGE_PIN U7 	 [get_ports {SEG[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[6]}]

set_property PACKAGE_PIN U2 	 [get_ports {AN[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]
set_property PACKAGE_PIN U4 	 [get_ports {AN[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]
set_property PACKAGE_PIN V4 	 [get_ports {AN[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]
set_property PACKAGE_PIN W4 	 [get_ports {AN[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]


##Pmod Header JC
##Sch name = JC3
set_property PACKAGE_PIN N17 	 [get_ports {TMP_SCL}]					
set_property IOSTANDARD LVCMOS33 [get_ports {TMP_SCL}]
set_property PULLUP TRUE         [get_ports {TMP_SCL}]
##Sch name = JC4
set_property PACKAGE_PIN P18 	 [get_ports {TMP_SDA}]					
set_property IOSTANDARD LVCMOS33 [get_ports {TMP_SDA}]
set_property PULLUP TRUE         [get_ports {TMP_SDA}]