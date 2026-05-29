# HDMI TX Clock (Flip L17 and L16)
set_property -dict { PACKAGE_PIN L16   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_clk_p }]; 
set_property -dict { PACKAGE_PIN L17   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_clk_n }];

# HDMI TX Data Assets (Ensuring no unconstrained ports)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_data_p[0] }];
set_property -dict { PACKAGE_PIN K18   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_data_n[0] }];
set_property -dict { PACKAGE_PIN K19   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_data_p[1] }];
set_property -dict { PACKAGE_PIN J19   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_data_n[1] }];
set_property -dict { PACKAGE_PIN J18   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_data_p[2] }];
set_property -dict { PACKAGE_PIN H18   IOSTANDARD TMDS_33 } [get_ports { TMDS_0_data_n[2] }];

# Map the stray reset port to Push Button 0 (BTN0)
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { reset_rtl }];