## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {phrase_select[0]}]; # sw[0]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {phrase_select[1]}]; # sw[1]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports {phrase_select[2]}]; # sw[2]
set_property -dict { PACKAGE_PIN R2    IOSTANDARD LVCMOS33 } [get_ports sw15              ]

## LEDs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led[0]} ]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {led[1]} ]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {led[2]} ]
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports  led15   ]

##Buttons
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports play ]; # btnC

##Pmod Header JB
set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports amp2_audio      ];#Sch name = JB1
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports amp2_gain       ];#Sch name = JB2
set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports amp2_shutdown_n ];#Sch name = JB4

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]