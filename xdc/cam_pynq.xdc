### ====================================================================
### SYSTEM INFRASTRUCTURE (From your cam_cap Canvas)
### ====================================================================

### PYNQ-Z2 125MHz Board System Clock
#set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports sys_clock]

### ====================================================================
### CAMERA INTERFACE PHYSICAL PINMAPPING (Example PMOD / Arduino Pins)
### ====================================================================
### NOTE: Swap out the PACKAGE_PIN values below to match the exact 
### hardware pins on your PYNQ-Z2 board where your camera module is plugged in.

### Camera Input Control Clocks & Synchronizations
#set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports PCLK]
#set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports VSYNC]
#set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports HREF]
#set_property -dict {PACKAGE_PIN V11  IOSTANDARD LVCMOS33} [get_ports XCLK]

### Allow PCLK to act as a normal routing clock without failing timing DRCs
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PCLK_IBUF]

### Camera Parallel Data Bus Pins (d[7:0])
#set_property -dict {PACKAGE_PIN T11  IOSTANDARD LVCMOS33} [get_ports {d[0]}]
#set_property -dict {PACKAGE_PIN T10  IOSTANDARD LVCMOS33} [get_ports {d[1]}]
#set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports {d[2]}]
#set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {d[3]}]
#set_property -dict {PACKAGE_PIN V12  IOSTANDARD LVCMOS33} [get_ports {d[4]}]
#set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33} [get_ports {d[5]}]
#set_property -dict {PACKAGE_PIN U12  IOSTANDARD LVCMOS33} [get_ports {d[6]}]
#set_property -dict {PACKAGE_PIN U11  IOSTANDARD LVCMOS33} [get_ports {d[7]}]

### ====================================================================
### EMIO I2C CAMERA CONTROL CONFIGURATION (Crucial Step!)
### ====================================================================
### Because you enabled EMIO I2C 0 inside the Zynq Processing Block,
### Vivado automatically names the generated top wrapper ports as shown below.
### This maps directly to your Arduino board physical header locations.

#set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports IIC_0_scl_io]
#set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports IIC_0_sda_io]

### Enable the physical pull-up resistors required for the I2C open-drain protocol
#set_property PULLUP true [get_ports IIC_0_scl_io]
#set_property PULLUP true [get_ports IIC_0_sda_io]
## ====================================================================
## SYSTEM INFRASTRUCTURE
## ====================================================================
## PYNQ-Z2 125MHz Board System Clock
#set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports sys_clock]

### ====================================================================
### CAMERA INTERFACE PHYSICAL PINMAPPING
### ====================================================================

### Camera Input Control Clocks & Synchronizations (Mapped to Arduino Base Analog/Digital Header Pins)
#set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports PCLK]
#set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports VSYNC]
#set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports HREF]
#set_property -dict {PACKAGE_PIN V11  IOSTANDARD LVCMOS33} [get_ports XCLK]

### Allow non-clock-dedicated hardware pins to route the camera clock through internal fabric buffers safely
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PCLK_IBUF]

### Camera Parallel Data Bus Pins (d[7:0])
### Perfectly matched to your board's PmodB and Arduino Digital Header track configurations:
#set_property -dict {PACKAGE_PIN T11  IOSTANDARD LVCMOS33} [get_ports {d[0]}]
#set_property -dict {PACKAGE_PIN T10  IOSTANDARD LVCMOS33} [get_ports {d[1]}]
#set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports {d[2]}]
#set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {d[3]}]
#set_property -dict {PACKAGE_PIN V12  IOSTANDARD LVCMOS33} [get_ports {d[4]}]
#set_property -dict {PACKAGE_PIN W13  IOSTANDARD LVCMOS33} [get_ports {d[5]}]
#set_property -dict {PACKAGE_PIN U12  IOSTANDARD LVCMOS33} [get_ports {d[6]}]
#set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports {d[7]}]

### ====================================================================
### EMIO I2C CAMERA CONTROL CONFIGURATION
### ====================================================================
### Mapped exactly to the auto-generated port name style Vivado outputs for I2C_0 on your canvas
### Routes out directly to your board's dedicated Arduino Direct I2C pins (P15/P16)

#set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports IIC_0_0_scl_io]
#set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports IIC_0_0_sda_io]

### Explicitly enable the physical internal pull-up resistor networks required for the I2C Bus protocol
#set_property PULLUP true [get_ports IIC_0_0_scl_io]
#set_property PULLUP true [get_ports IIC_0_0_sda_io]
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
## ====================================================================
## SYSTEM CLOCK (Required for internal FPGA clock generation / wizard)
## ====================================================================
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports sys_clock]

## ====================================================================
## 1. CONTROL & FRAME SYNCHRONIZATION CLOCKS
## [!] PHYSICAL WIRE CONNECTIONS: Plug these 4 into the ANALOG Header slots (A0 - A3)
## ====================================================================
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports PCLK]   ; # Physical Pin Label: A0
set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports VSYNC]  ; # Physical Pin Label: A1
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports HREF]   ; # Physical Pin Label: A2
set_property -dict {PACKAGE_PIN V11  IOSTANDARD LVCMOS33} [get_ports XCLK]   ; # Physical Pin Label: A3

## Forces internal clock routing logic to handle the camera clock without errors
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PCLK_IBUF]

## ====================================================================
## 2. 8-BIT PARALLEL VIDEO DATA BUS (d[7:0])
## [!] PHYSICAL WIRE CONNECTIONS: Split across PMODB and ARDUINO DIGITAL headers
## ====================================================================
set_property -dict {PACKAGE_PIN T11  IOSTANDARD LVCMOS33} [get_ports {d[0]}]; # PmodB Bottom Row Pin 3
set_property -dict {PACKAGE_PIN T10  IOSTANDARD LVCMOS33} [get_ports {d[1]}]; # PmodB Bottom Row Pin 4
set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports {d[2]}]; # PmodB Top Row Pin 3
set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {d[3]}]; # PmodB Top Row Pin 4
set_property -dict {PACKAGE_PIN V12  IOSTANDARD LVCMOS33} [get_ports {d[4]}]; # PmodB Bottom Row Pin 1
set_property -dict {PACKAGE_PIN W13  IOSTANDARD LVCMOS33} [get_ports {d[5]}]; # PmodB Bottom Row Pin 2
set_property -dict {PACKAGE_PIN U12  IOSTANDARD LVCMOS33} [get_ports {d[6]}]; # Arduino Digital Pin D1
set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports {d[7]}]; # Arduino Digital Pin D0

## ====================================================================
## 3. EMIO I2C CAMERA SERIAL CONTROL INTERFACE (SCCB)
## [!] PHYSICAL WIRE CONNECTIONS: Plug into dedicated SCL/SDA sockets near the board edge
## ====================================================================
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports IIC_0_0_scl_io]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports IIC_0_0_sda_io]