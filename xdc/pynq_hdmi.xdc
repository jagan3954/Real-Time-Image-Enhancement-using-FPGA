## PYNQ-Z2 System Clock (125 MHz)
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk_in1_0]
create_clock -period 8.000 -name sys_clk [get_ports clk_in1_0]


set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets design_1_i/clk_wiz_0/inst/clk_in1_design_1_clk_wiz_0_0]
## HDMI TX Output (PYNQ-Z2)
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports hdmi_out_clk_p]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports hdmi_out_clk_n]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[0]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[0]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[1]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[2]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[2]}]

## Board Reset Button (D19)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports reset]