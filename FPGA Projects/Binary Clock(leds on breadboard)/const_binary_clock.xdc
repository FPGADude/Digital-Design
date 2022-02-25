# Design constraints file for the Binary Clock on BASYS 3 FPGA boad

# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk_100MHz]							
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100MHz]

##Buttons
set_property PACKAGE_PIN W19 	 [get_ports btn_hr]						
set_property IOSTANDARD LVCMOS33 [get_ports btn_hr]
set_property PACKAGE_PIN T17 	 [get_ports btn_min]
set_property IOSTANDARD LVCMOS33 [get_ports btn_min]

##Pmod Header JA
##Sch name = JA1
set_property PACKAGE_PIN J1 	 [get_ports {hour[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hour[3]}]
##Sch name = JA2                             
set_property PACKAGE_PIN L2 	 [get_ports {hour[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hour[2]}]
##Sch name = JA3                            
set_property PACKAGE_PIN J2 	 [get_ports {hour[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hour[1]}]
##Sch name = JA4                             
set_property PACKAGE_PIN G2 	 [get_ports {hour[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hour[0]}]
##Sch name = JA7
set_property PACKAGE_PIN H1 	 [get_ports {blink}]					
set_property IOSTANDARD LVCMOS33 [get_ports {blink}]

##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 	 [get_ports {minute[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {minute[5]}]
##Sch name = JB2                            
set_property PACKAGE_PIN A16 	 [get_ports {minute[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {minute[4]}]
##Sch name = JB3                           
set_property PACKAGE_PIN B15 	 [get_ports {minute[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {minute[3]}]
##Sch name = JB4                            
set_property PACKAGE_PIN B16 	 [get_ports {minute[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {minute[2]}]
##Sch name = JB7                            
set_property PACKAGE_PIN A15 	 [get_ports {minute[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {minute[1]}]
##Sch name = JB8                            
set_property PACKAGE_PIN A17 	 [get_ports {minute[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {minute[0]}]


