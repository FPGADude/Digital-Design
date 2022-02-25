# LEDs
set_property PACKAGE_PIN U16 	 [get_ports {data_out[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[0]}]
set_property PACKAGE_PIN E19 	 [get_ports {data_out[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[1]}]
set_property PACKAGE_PIN U19 	 [get_ports {data_out[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[2]}]
set_property PACKAGE_PIN V19 	 [get_ports {data_out[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_out[3]}]

##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 	 [get_ports {addr[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {addr[0]}]
##Sch name = JB2                            
set_property PACKAGE_PIN A16 	 [get_ports {addr[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {addr[1]}]
##Sch name = JB3                            
set_property PACKAGE_PIN B15 	 [get_ports {addr[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {addr[2]}]
##Sch name = JB4                            
set_property PACKAGE_PIN B16 	 [get_ports {addr[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {addr[3]}]
##Sch name = JB7
set_property PACKAGE_PIN A15 	 [get_ports {data_in[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_in[0]}]
##Sch name = JB8                            
set_property PACKAGE_PIN A17 	 [get_ports {data_in[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_in[1]}]
##Sch name = JB9                            
set_property PACKAGE_PIN C15 	 [get_ports {data_in[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_in[2]}]
##Sch name = JB10                           
set_property PACKAGE_PIN C16 	 [get_ports {data_in[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {data_in[3]}]
 


##Pmod Header JC
##Sch name = JC7
set_property PACKAGE_PIN L17 	 [get_ports {sync_in}]					
set_property IOSTANDARD LVCMOS33 [get_ports {sync_in}]
##Sch name = JC2
set_property PACKAGE_PIN M18 	 [get_ports {wr_en}]					
set_property IOSTANDARD LVCMOS33 [get_ports {wr_en}]