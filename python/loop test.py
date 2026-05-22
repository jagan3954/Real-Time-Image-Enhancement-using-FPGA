 from pynq import Overlay, MMIO, allocate

import numpy as np

import cv2

import matplotlib.pyplot as plt

import time

​

overlay = Overlay("./Bitstreamfiles/loop_main.bit")

​

IMG_WIDTH = 640

IMG_HEIGHT = 480

STRIDE = IMG_WIDTH * 4

​

img = cv2.imread("test.jpg")

img = cv2.resize(img, (IMG_WIDTH, IMG_HEIGHT))

img_rgba = cv2.cvtColor(img, cv2.COLOR_BGR2RGBA)

​

in_buffer = allocate(shape=(IMG_HEIGHT, IMG_WIDTH, 4), dtype=np.uint8)

out_buffer = allocate(shape=(IMG_HEIGHT, IMG_WIDTH, 4), dtype=np.uint8)

in_buffer[:] = img_rgba

out_buffer[:] = 0

in_buffer.flush()

out_buffer.flush()

​

vdma = MMIO(overlay.ip_dict['axi_vdma_0']['phys_addr'], 0x10000)

​

# Reset

vdma.write(0x00, 0x4)

vdma.write(0x30, 0x4)

time.sleep(0.2)

​

# Run

vdma.write(0x00, 0x00000001)

vdma.write(0x30, 0x00000001)

​

# Addresses

vdma.write(0x5C, in_buffer.physical_address)

vdma.write(0xAC, out_buffer.physical_address)

​

# Hsize stride

vdma.write(0x54, STRIDE)

vdma.write(0x58, STRIDE)

vdma.write(0xA4, STRIDE)

vdma.write(0xA8, STRIDE)

​

# Fire

vdma.write(0xA0, IMG_HEIGHT)

vdma.write(0x50, IMG_HEIGHT)

​

print("Polling...")

timeout = time.time() + 5.0

while time.time() < timeout:

s2mm = vdma.read(0x34)

mm2s = vdma.read(0x04)

print(f" S2MM:{hex(s2mm)} MM2S:{hex(mm2s)}")

if s2mm & 0x1000:

print("Done")

break

time.sleep(0.2)

else:

print("Timeout")

​

out_buffer.invalidate()

print(f"Unique: {np.unique(np.array(out_buffer))[:10]}")

​

plt.figure(figsize=(12,5))

plt.subplot(1,2,1)

plt.imshow(cv2.cvtColor(img_rgba, cv2.COLOR_RGBA2RGB))

plt.title("Original")

plt.subplot(1,2,2)

plt.imshow(cv2.cvtColor(np.array(out_buffer), cv2.COLOR_RGBA2RGB))

plt.title("Loopback")

plt.show()

​

in_buffer.freebuffer()

out_buffer.freebuffer()
