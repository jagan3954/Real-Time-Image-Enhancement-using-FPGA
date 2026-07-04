#set_property PACKAGE_PIN K17 [get_ports {TMDSp[0]}]
#set_property PACKAGE_PIN K19 [get_ports {TMDSp[1]}]
#set_property PACKAGE_PIN J18 [get_ports {TMDSp[2]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDSp[0]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDSn[0]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDSp[1]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDSn[1]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDSp[2]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDSn[2]}]

#set_property PACKAGE_PIN H16 [get_ports clk]
#set_property IOSTANDARD LVCMOS33 [get_ports clk]

#set_property PACKAGE_PIN L16 [get_ports TMDSp_clock]
#set_property IOSTANDARD TMDS_33 [get_ports TMDSp_clock]

## System Clock Input (125MHz Pin from PYNQ-Z2)
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} [get_ports clk]

## HDMI TX Clock Lanes
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports TMDSp_clock]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports TMDSn_clock]

## HDMI TX Data Lanes
set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {TMDSp[0]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {TMDSn[0]}]

set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {TMDSp[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {TMDSn[1]}]

set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {TMDSp[2]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {TMDSn[2]}]

## Tell Vivado to handle the internal MMCM clock relationships as a synchronous group
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins clock_gen_inst/MMCME2_BASE_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins clock_gen_inst/MMCME2_BASE_inst/CLKOUT1]]