from pynq import Overlay, MMIO, allocate
import numpy as np
import cv2
import matplotlib.pyplot as plt
import time

# --- 1. SETTINGS & PATHS ---
# Paths updated to match your board's structure
bit_path = "Bitstreamfiles/gray_brigh.bit"  
img_path = "test.jpg"

IMG_WIDTH = 640
IMG_HEIGHT = 480
STRIDE = IMG_WIDTH * 4
BRIGHTNESS_VALUE = 75 # Adjust this (0-255) to see the change!

# --- 2. LOAD HARDWARE ---
print(f"Loading Bitstream: {bit_path}...")
overlay = Overlay(bit_path)
print("IPs Found:", list(overlay.ip_dict.keys()))

# --- 3. SETUP CONTROL UNIT (AXI-LITE) ---
# We use the exact name Vivado gave your top-level module
ctrl_name = 'img_pro_top_loop_bac_0'

if ctrl_name in overlay.ip_dict:
    print(f"Connecting to Control Unit: {ctrl_name}")
    ctrl_base = overlay.ip_dict[ctrl_name]['phys_addr']
    ctrl = MMIO(ctrl_base, 0x100)
    
    # Write brightness to Register 0 (Offset 0x00)
    ctrl.write(0x00, BRIGHTNESS_VALUE)
    print(f"Hardware Brightness Set to: +{BRIGHTNESS_VALUE}")
else:
    raise RuntimeError(f"Could not find {ctrl_name}. Check your Vivado Block Design name!")

# --- 4. PREPARE IMAGE ---
img = cv2.imread(img_path)
if img is None:
    raise FileNotFoundError(f"Could not find {img_path}")

img = cv2.resize(img, (IMG_WIDTH, IMG_HEIGHT))
img_rgba = cv2.cvtColor(img, cv2.COLOR_BGR2RGBA)

# --- 5. ALLOCATE PHYSICALLY CONTIGUOUS MEMORY ---
in_buffer = allocate(shape=(IMG_HEIGHT, IMG_WIDTH, 4), dtype=np.uint8)
out_buffer = allocate(shape=(IMG_HEIGHT, IMG_WIDTH, 4), dtype=np.uint8)

in_buffer[:] = img_rgba
out_buffer[:] = 0

in_buffer.flush()
out_buffer.flush()
# --- 6. INITIALIZE VDMA (Direct Address Access) ---
# We use the ip_dict to get the address directly to avoid the driver error
vdma_base = overlay.ip_dict['axi_vdma_0']['phys_addr']
vdma = MMIO(vdma_base, 0x10000)

print(f"VDMA found at: {hex(vdma_base)}")
print("Starting VDMA...")

# Reset VDMA
vdma.write(0x00, 0x4)  # MM2S Reset
vdma.write(0x30, 0x4)  # S2MM Reset
time.sleep(0.1)

# Start VDMA Channels
vdma.write(0x00, 0x01) # MM2S Start
vdma.write(0x30, 0x01) # S2MM Start

# Set Physical Addresses
vdma.write(0x5C, in_buffer.physical_address)
vdma.write(0xAC, out_buffer.physical_address)

# Set HSIZE and STRIDE
vdma.write(0x54, STRIDE)
vdma.write(0x58, STRIDE)
vdma.write(0xA4, STRIDE)
vdma.write(0xA8, STRIDE)

# Fire the transfer (Receiver first, then Transmitter)
vdma.write(0xA0, IMG_HEIGHT) 
vdma.write(0x50, IMG_HEIGHT)


# --- 7. WAIT FOR COMPLETION ---
done = False
for _ in range(10):
    if vdma.read(0x34) & 0x1000:
        print("Transfer Successful!")
        done = True
        break
    time.sleep(0.1)

if not done:
    print("Transfer timed out. Check hardware handshakes.")

# --- 8. DISPLAY RESULTS ---
out_buffer.invalidate()
result_img = np.array(out_buffer)

plt.figure(figsize=(12, 6))
plt.subplot(1, 2, 1)
plt.imshow(cv2.cvtColor(img_rgba, cv2.COLOR_RGBA2RGB))
plt.title("Original Input")

plt.subplot(1, 2, 2)
# Convert result to RGB for display
plt.imshow(cv2.cvtColor(result_img, cv2.COLOR_RGBA2RGB))
plt.title(f"Grayscale + Brightness (+{BRIGHTNESS_VALUE})")
plt.show()

# --- 9. CLEANUP ---
in_buffer.freebuffer()
out_buffer.freebuffer()
