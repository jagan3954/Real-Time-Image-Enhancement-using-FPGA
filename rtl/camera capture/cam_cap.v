module camera_capture #(
    parameter H_ACTIVE = 640,   // Change to 1920 for 1080p, 1280 for 720p
    parameter V_ACTIVE = 480    // Change to 1080 or 720
)(
    input  wire        pclk,
    input  wire        rst_n,
    // Camera interface
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  d,
    // AXI4-Stream Master
    output reg         m_axis_tvalid,
    output reg  [23:0] m_axis_tdata,
    output reg         m_axis_tuser,
    output reg         m_axis_tlast
);
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *)
(* X_INTERFACE_PARAMETER = "XILINX_LEGACY_IP_NAME=camera_capture, ASSOCIATED_BUSIF=m_axis, ASSOCIATED_RESET=rst_n" *)
    reg [7:0]  d_latch;
    reg        byte_idx;
    reg [15:0] pixel_cnt;
    reg        vsync_old;
    reg        frame_start_flag;

    always @(posedge pclk) begin
        if (!rst_n) begin
            vsync_old        <= 0;
            frame_start_flag <= 0;
            pixel_cnt        <= 0;
            byte_idx         <= 0;
            d_latch          <= 0;
            m_axis_tvalid    <= 0;
            m_axis_tdata     <= 0;
            m_axis_tuser     <= 0;
            m_axis_tlast     <= 0;
        end else begin
            vsync_old <= vsync;

            // Detect rising edge of VSYNC (start of new frame)
            if (vsync && !vsync_old) begin
                frame_start_flag <= 1'b1;
                pixel_cnt        <= 0;
                byte_idx         <= 0;
            end

            // Default outputs
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
            m_axis_tuser  <= 1'b0;

            // HREF high = valid pixel row
            if (href) begin
                byte_idx <= ~byte_idx;  // Toggle 0/1

                if (byte_idx == 0) begin
                    d_latch <= d;  // Latch first byte
                end else begin
                    // Safeguard: Only send pixels if we haven't exceeded the expected row width
                    if (pixel_cnt < H_ACTIVE) begin
                        // Second byte: assemble RGB565 → RGB888
                        m_axis_tdata[23:16] <= {d_latch[7:3], d_latch[7:5]};          // R 5→8
                        m_axis_tdata[15:8]  <= {d_latch[2:0], d[7:5], d_latch[2:1]};   // G 6→8 (FIXED)
                        m_axis_tdata[7:0]   <= {d[4:0], d[4:2]};                      // B 5→8

                        m_axis_tvalid <= 1'b1;

                        // SOF on first pixel
                        if (frame_start_flag) begin
                            m_axis_tuser     <= 1'b1;
                            frame_start_flag <= 1'b0;
                        end

                        // EOL on last pixel of row
                        if (pixel_cnt == H_ACTIVE - 1) begin
                            m_axis_tlast <= 1'b1;
                            pixel_cnt    <= 0;
                        end else begin
                            pixel_cnt <= pixel_cnt + 1'b1;
                        end
                    end
                end
            end else begin
                byte_idx  <= 0;  // Reset on HREF low
                pixel_cnt <= 0;  // Force reset row counter between lines
            end
        end
    end

endmodule
