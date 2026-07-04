# 🚀 STEP-BY-STEP RUN GUIDE: CUSTOM RTL VIDEO LOOPBACK CORE

This guide provides the complete blueprint for setting up, wiring, and running the Custom RTL Image Processing Loopback Pipeline on the physical PYNQ-Z2 development board using an OV7670 Parallel CMOS Image Sensor.

## 📋 Prerequisites & Hardware Checklist

Ensure you have the following components ready before starting the configuration:

*   **Development Board:** PYNQ-Z2 (with an active MicroSD card flashed with the standard PYNQ OS image).
*   **Camera Module:** OV7670 18-Pin Parallel CMOS Sensor (Non-FIFO version).
*   **Jumper Wires:** Female-to-Female premium ribbon cables.
*   **Network Setup:** Ethernet cable bridging the PYNQ-Z2 board directly to your host computer or local network router.

## 🔌 Step 1: Physical Hardware Wiring Matrix

The digital capture engine relies entirely on precise synchronous hardware signals. Do not use the Arduino digital slots (AR0, AR1) for clock signals. Wire the camera to the board pins exactly as mapped below:

| OV7670 Camera Pin | PYNQ-Z2 Header Target     | Physical Board Pin Label | Description                  |
| ----------------- | ------------------------- | ------------------------ | ---------------------------- |
| PCLK              | Analog Header (Slot 0)    | A0 (Pin Y11)             | Pixel Clock Input            |
| VSYNC             | Analog Header (Slot 1)    | A1 (Pin Y12)             | Vertical Frame Sync Input    |
| HREF              | Analog Header (Slot 2)    | A2 (Pin W11)             | Horizontal Row Valid Input   |
| XCLK              | Analog Header (Slot 3)    | A3 (Pin V11)             | System Master Clock Output   |
| D0                | Arduino Digital Header    | D0 (Pin T14)             | Parallel Video Data Bit 7    |
| D1                | Arduino Digital Header    | D1 (Pin U12)             | Parallel Video Data Bit 6    |
| D2                | PMODB Header (Bottom Row) | Pin 2 (Pin W13)          | Parallel Video Data Bit 5    |
| D3                | PMODB Header (Bottom Row) | Pin 1 (Pin V12)          | Parallel Video Data Bit 4    |
| D4                | PMODB Header (Top Row)    | Pin 4 (Pin W10)          | Parallel Video Data Bit 3    |
| D5                | PMODB Header (Top Row)    | Pin 3 (Pin V10)          | Parallel Video Data Bit 2    |
| D6                | PMODB Header (Bottom Row) | Pin 4 (Pin T10)          | Parallel Video Data Bit 1    |
| D7                | PMODB Header (Bottom Row) | Pin 3 (Pin T11)          | Parallel Video Data Bit 0    |
| SCL               | Dedicated I2C Edge Socket | SCL (Pin P15)            | SCCB Control Clock           |
| SDA               | Dedicated I2C Edge Socket | SDA (Pin P16)            | SCCB Control Data            |
| VCC               | Power Bus Header          | 3.3V                     | Main Power Supply            |
| GND               | Power Bus Header          | GND                      | System Common Ground         |

## 🛠️ Step 2: Preparing the Vivado Project Bits

Before running the deployment script, make sure your compiled bitstream from the GitHub repository is placed in the correct directory structure on your PYNQ board.

1.  Inside your project workspace on the PYNQ board, verify or create a directory named `Bitstreamfiles/`.
2.  The bitstream for this camera setup is located in the `fixining enchancement` folder.
3.  Place your synthesized bitstream file and its hardware description file into that folder. They must share the exact same root filename:
    *   `Bitstreamfiles/fixining enchancement/cam_con_ip.bit`
    *   `Bitstreamfiles/fixining enchancement/cam_con_ip.hwh`

## 💻 Step 3: Software Deployment & Web Execution

To spin up the real-time processing stream, follow this software execution sequence.

### 1. Establish an SSH Connection or Open Jupyter

Access the terminal of your running PYNQ platform. You can log in via SSH from your computer's terminal:

```bash
ssh xilinx@192.168.2.99
# Default Password: xilinx
```

Alternatively, navigate to `http://192.168.2.99:9090` in your web browser and open a fresh terminal or a new Python 3 notebook.

### 2. Install Required Framework Dependencies

The streaming interface operates via Flask and OpenCV. Install them onto your board's environment using `pip`:

```bash
pip install Flask opencv-python numpy
```

### 3. Create the Execution Script

Create a new file named `run_stream.py` inside your working directory and paste the following Python code inside.

```python
import os, cv2, time, fcntl, numpy as np
from flask import Flask, Response, render_template_string
from pynq import Overlay, allocate

# --- CONFIGURATION ---
BITSTREAM_PATH = "Bitstreamfiles/fixining enchancement/cam_con_ip.bit"
CAMERA_I2C_ADDRESS = 0x21
FRAME_WIDTH, FRAME_HEIGHT = 640, 480

# 1. Load Hardware Overlay
print(f"🔄 Step 1: Loading project FPGA hardware overlay from {BITSTREAM_PATH}...")
overlay = Overlay(BITSTREAM_PATH)
print("✅ Overlay loaded successfully!")

# 2. Setup Camera Registers via Linux Native I2C
def write_camera_reg(reg, value):
    """Writes a value to a specific register on the I2C-controlled camera."""
    # Use /dev/i2c-0 for the PYNQ-Z2's main I2C bus connected to headers
    i2c_bus = os.open("/dev/i2c-0", os.O_RDWR)
    try:
        # Set the I2C slave address for the camera
        fcntl.ioctl(i2c_bus, 0x0703, CAMERA_I2C_ADDRESS)
        # Write the register and value pair
        os.write(i2c_bus, bytes([reg, value]))
        time.sleep(0.001) # Small delay for register to settle
    finally:
        os.close(i2c_bus)

print("🔄 Step 2: Initializing camera sensor registers...")
write_camera_reg(0x12, 0x80) # Global Hardware Reset
time.sleep(0.1)
write_camera_reg(0x12, 0x04) # Set RGB Output Mode
write_camera_reg(0x40, 0xD0) # Enable RGB565 format
print("✅ Camera sensor hardware initialization complete!")

# 3. Memory Allocation Setup
print(f"🔄 Step 3: Allocating hardware contiguous frame buffer ({FRAME_WIDTH}x{FRAME_HEIGHT})...")
frame_buffer = allocate(shape=(FRAME_HEIGHT, FRAME_WIDTH, 3), dtype=np.uint8)
print("✅ Memory structures active!")

def capture_fpga_frame():
    """
    Invalidates cache and captures the current frame from the hardware buffer.
    Provides a fallback visual if the hardware signal is not present.
    """
    global frame_buffer
    frame_buffer.invalidate() # Force cache clear to get the latest data from hardware
    
    # Diagnostic fallback: If buffer is all zeros, it means no data is coming from FPGA.
    # Show a pulsing screen to indicate the software is running but waiting for a signal.
    if np.all(frame_buffer == 0):
         t = time.time()
         pulse_color = int((np.sin(t * 3) + 1) * 20) + 30
         return np.full((FRAME_HEIGHT, FRAME_WIDTH, 3), [pulse_color, pulse_color, pulse_color], dtype=np.uint8)
    
    return frame_buffer

# 4. Web Engine Setup
app = Flask(__name__)

def generate_video_stream():
    """Continuously captures frames and encodes them as a JPEG stream."""
    while True:
        frame_data = capture_fpga_frame()
        success, encoded_image = cv2.imencode('.jpg', frame_data)
        if not success:
            continue
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + encoded_image.tobytes() + b'\r\n')
        time.sleep(0.03) # Limit frame rate to ~30 FPS

@app.route('/')
def index():
    """Renders the main video monitoring page."""
    return render_template_string("""
    <html>
        <head><title>PYNQ Video Monitoring Pipeline</title></head>
        <body style="background-color: #0c0e14; color: white; text-align: center; font-family: sans-serif; padding-top: 50px;">
            <h1 style="color: #00ffcc;">Live Camera Pipeline Stream</h1>
            <p style="color: #6272a4;">Active Target Overlay: <b>{{ bitstream_path }}</b></p>
            <div style="margin-top: 20px;">
                <img src="{{ url_for('video_feed') }}" style="border: 4px solid #44475a; border-radius: 8px; width: 640px; height: 480px;">
            </div>
        </body>
    </html>
    """, bitstream_path=BITSTREAM_PATH)

@app.route('/video_feed')
def video_feed():
    """The video streaming route."""
    return Response(generate_video_stream(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    print("\n🚀 Launching web server...")
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)
```

### 4. Run the Pipeline

Launch the script with `sudo` (administrator privileges) to permit direct access to the physical memory maps and system hardware buses:

```bash
sudo python3 run_stream.py
```

## 📺 Step 4: Accessing Your Monitor Screen Output

Once the console returns `Running on http://0.0.0.0:5000`:

1.  Open up a web browser window on your host computer.
2.  Navigate directly to your PYNQ's IP address at port 5000: `http://192.168.2.99:5000`

*   **If you see a pulsing dark screen:** Your code and web server are fully functioning, but the hardware core is waiting for valid camera sync input. This is a debugging feature. **Check your physical PCLK, VSYNC, and HREF wiring connections immediately.**
*   **If you see a live video matrix:** Congratulations! Your custom RTL hardware loopback processing accelerator is actively processing pixels from the camera and transmitting data smoothly.