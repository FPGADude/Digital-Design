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
set_property PACKAGE_PIN J1 	 [get_ports {hr1_out[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hr1_out[6]}]
##Sch name = JA2                            
set_property PACKAGE_PIN L2 	 [get_ports {hr1_out[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hr1_out[5]}]
##Sch name = JA3                             
set_property PACKAGE_PIN J2 	 [get_ports {hr1_out[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hr1_out[4]}]
##Sch name = JA4                             
set_property PACKAGE_PIN G2 	 [get_ports {hr1_out[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hr1_out[3]}]
##Sch name = JA7                            
set_property PACKAGE_PIN H1 	 [get_ports {hr1_out[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hr1_out[2]}]
##Sch name = JA8                             
set_property PACKAGE_PIN K2 	 [get_ports {hr1_out[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hr1_out[1]}]
##Sch name = JA9                           
set_property PACKAGE_PIN H2 	 [get_ports {hr1_out[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {hr1_out[0]}]

##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 	 [get_ports {min0_out[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min0_out[6]}]
##Sch name = JB2                             
set_property PACKAGE_PIN A16 	 [get_ports {min0_out[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min0_out[5]}]
##Sch name = JB3                             
set_property PACKAGE_PIN B15 	 [get_ports {min0_out[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min0_out[4]}]
##Sch name = JB4                            
set_property PACKAGE_PIN B16 	 [get_ports {min0_out[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min0_out[3]}]
##Sch name = JB7                            
set_property PACKAGE_PIN A15 	 [get_ports {min0_out[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min0_out[2]}]
##Sch name = JB8                           
set_property PACKAGE_PIN A17 	 [get_ports {min0_out[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min0_out[1]}]
##Sch name = JB9                            
set_property PACKAGE_PIN C15 	 [get_ports {min0_out[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min0_out[0]}]

##Pmod Header JC
##Sch name = JC1
set_property PACKAGE_PIN K17 	 [get_ports {min1_out[6]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min1_out[6]}]
##Sch name = JC2                             
set_property PACKAGE_PIN M18 	 [get_ports {min1_out[5]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min1_out[5]}]
##Sch name = JC3                            
set_property PACKAGE_PIN N17 	 [get_ports {min1_out[4]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min1_out[4]}]
##Sch name = JC4                            
set_property PACKAGE_PIN P18 	 [get_ports {min1_out[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min1_out[3]}]
##Sch name = JC7                             
set_property PACKAGE_PIN L17 	 [get_ports {min1_out[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min1_out[2]}]
##Sch name = JC8                            
set_property PACKAGE_PIN M19 	 [get_ports {min1_out[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min1_out[1]}]
##Sch name = JC9                            
set_property PACKAGE_PIN P17 	 [get_ports {min1_out[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {min1_out[0]}]
##Sch name = JC10                            
set_property PACKAGE_PIN R18 	 [get_ports {blink}]					
set_property IOSTANDARD LVCMOS33 [get_ports {blink}]

#Pmod Header JXADC
#Sch name = XA1_P
set_property PACKAGE_PIN J3 	 [get_ports {hr0_out[6]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {hr0_out[6]}]
#Sch name = XA2_P                            
set_property PACKAGE_PIN L3 	 [get_ports {hr0_out[5]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {hr0_out[5]}]
#Sch name = XA3_P                            
set_property PACKAGE_PIN M2 	 [get_ports {hr0_out[4]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {hr0_out[4]}]
#Sch name = XA4_P                            
set_property PACKAGE_PIN N2 	 [get_ports {hr0_out[3]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {hr0_out[3]}]
#Sch name = XA1_N                           
set_property PACKAGE_PIN K3 	 [get_ports {hr0_out[2]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {hr0_out[2]}]
#Sch name = XA2_N                            
set_property PACKAGE_PIN M3 	 [get_ports {hr0_out[1]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {hr0_out[1]}]
#Sch name = XA3_N                            
set_property PACKAGE_PIN M1 	 [get_ports {hr0_out[0]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {hr0_out[0]}]

