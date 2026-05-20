# 🎨 Zynq Image Processing Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FPGA](https://img.shields.io/badge/Target-Zynq%207020-blue)](https://www.xilinx.com/products/silicon-devices/soc/zynq-7000.html)
[![Verilog](https://img.shields.io/badge/Verilog-1995-green)](https://ieeexplore.ieee.org/document/6011393)
[![Python](https://img.shields.io/badge/Python-3.6+-blue)](https://www.python.org/)

> **Real-time image processing on PYNQ-Z2 using PS/PL architecture**  
> *ARM controls, FPGA processes — pixels at 100 MHz*

---

## 📋 Table of Contents
- [Architecture Overview](#-architecture-overview)
- [Hardware Requirements](#-hardware-requirements)
- [Project Structure](#-project-structure)
- [Data Flow](#-data-flow)
- [Control Registers](#-control-registers)
- [Getting Started](#-getting-started)
- [Verilog Modules](#-verilog-modules)
- [Python Control](#-python-control)
- [Resource Utilization](#-resource-utilization)
- [Performance](#-performance)
- [License](#-license)

---

## 🏗 Architecture Overview



---

## 💻 Hardware Requirements

| Component | Specification |
|-----------|---------------|
| **Board** | PYNQ-Z2 (Zynq XC7Z020-1CLG400C) |
| **PL Clock** | 100 MHz |
| **PS Clock** | 666 MHz |
| **Memory** | 512 MB DDR3 |
| **Resolution** | 640×480 (configurable) |
| **Pixel Format** | 24-bit RGB → 8-bit Grayscale |

---

## 📁 Project Structure



---

## 🔄 Data Flow

### Data Width Journey

| Stage | Input Width | Output Width | Operation |
|-------|-------------|--------------|-----------|
| VDMA Read | - | 24-bit RGB | Memory read |
| Preprocessing | 24-bit RGB | 8-bit Gray | Fixed-point luminance |
| Brightness | 8-bit | 8-bit | Add offset, clamp |
| Contrast | 8-bit | 8-bit | Stretch or HistEQ |
| Noise Filter | 8-bit | 8-bit | 3×3 spatial filtering |
| Edge Unit | 8-bit | 8-bit | Sobel/Laplacian |
| Delay FIFO | 8-bit | 8-bit | Pipeline alignment |
| Pixel Adder | 8-bit + 8-bit | 8-bit | Edge blending |
| Output Formatter | 8-bit | 24-bit RGB | `{gray,gray,gray}` |
| VDMA Write | 24-bit RGB | - | Memory write |

### Key Signals



---

## 🎮 Control Registers

AXI4-Lite register map (32-bit aligned, offset by 4 bytes):

| Address | Register Name | Bits | Values |
|---------|---------------|------|--------|
| `0x00` | `brightness_offset` | [8:0] | signed -255 to +255 |
| `0x04` | `contrast_mode` | [1:0] | `00`=off, `01`=stretch, `10`=histeq |
| `0x08` | `noise_sel` | [1:0] | `00`=off, `01`=mean, `10`=median, `11`=gaussian |
| `0x0C` | `edge_sel` | [1:0] | `00`=off, `01`=sobel, `10`=laplacian |
| `0x10` | `edge_alpha` | [7:0] | 0 to 255 (sharpening strength) |
| `0x14` | `threshold_en` | [0] | `0`=off, `1`=on |
| `0x18` | `threshold_val` | [7:0] | 0 to 255 |
| `0x1C` | `status` | [0] | **read-only:** `1`=frame done |

---

for use 
```bash
git clone https://github.com/yourusername/zynq-image-processor.git
cd zynq-image-processor

