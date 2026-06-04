## ====================================================================
## SYSTEM INFRASTRUCTURE (From your cam_cap Canvas)
## ====================================================================

## PYNQ-Z2 125MHz Board System Clock
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports sys_clock]

## ====================================================================
## CAMERA INTERFACE PHYSICAL PINMAPPING (Example PMOD / Arduino Pins)
## ====================================================================
## NOTE: Swap out the PACKAGE_PIN values below to match the exact 
## hardware pins on your PYNQ-Z2 board where your camera module is plugged in.

## Camera Input Control Clocks & Synchronizations
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports PCLK]
set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports VSYNC]
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports HREF]
set_property -dict {PACKAGE_PIN V11  IOSTANDARD LVCMOS33} [get_ports XCLK]

## Allow PCLK to act as a normal routing clock without failing timing DRCs
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PCLK_IBUF]

## Camera Parallel Data Bus Pins (d[7:0])
set_property -dict {PACKAGE_PIN T11  IOSTANDARD LVCMOS33} [get_ports {d[0]}]
set_property -dict {PACKAGE_PIN T10  IOSTANDARD LVCMOS33} [get_ports {d[1]}]
set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports {d[2]}]
set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {d[3]}]
set_property -dict {PACKAGE_PIN V12  IOSTANDARD LVCMOS33} [get_ports {d[4]}]
set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33} [get_ports {d[5]}]
set_property -dict {PACKAGE_PIN U12  IOSTANDARD LVCMOS33} [get_ports {d[6]}]
set_property -dict {PACKAGE_PIN U11  IOSTANDARD LVCMOS33} [get_ports {d[7]}]

## ====================================================================
## EMIO I2C CAMERA CONTROL CONFIGURATION (Crucial Step!)
## ====================================================================
## Because you enabled EMIO I2C 0 inside the Zynq Processing Block,
## Vivado automatically names the generated top wrapper ports as shown below.
## This maps directly to your Arduino board physical header locations.

set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports IIC_0_scl_io]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports IIC_0_sda_io]

## Enable the physical pull-up resistors required for the I2C open-drain protocol
set_property PULLUP true [get_ports IIC_0_scl_io]
set_property PULLUP true [get_ports IIC_0_sda_io]