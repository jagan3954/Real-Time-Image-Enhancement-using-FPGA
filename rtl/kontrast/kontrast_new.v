module contrast_enhance (
    // Slave Interface (Input)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,
    // Master Interface (Output)
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tuser,
    output wire        m_axis_tlast
);
    // --- Parameters (tune these to adjust contrast) ---
    // Gain:  Q2.6 fixed-point. 1.5x = 96  (1.5 * 64)
    // Bias:  signed offset applied after gain (acts as brightness trim)
    parameter [7:0]  GAIN  = 8'd96;   // 1.5x in Q2.6 fixed-point
    parameter signed [8:0] BIAS = -9'sd32; // shift midpoint down to keep output centered

    // 1. Unpack the bytes (same layout as rgba_to_gray)
    wire [7:0] r = s_axis_tdata[7:0];
    wire [7:0] g = s_axis_tdata[15:8];
    wire [7:0] b = s_axis_tdata[23:16];
    wire [7:0] a = s_axis_tdata[31:24];

    // 2. Contrast Math:  out = clamp( (in * GAIN) >> 6 + BIAS, 0, 255 )
    //    Each channel is independent — color ratios are preserved.
    //    Multiplier is 8x8 → 16-bit result; shift right 6 recovers integer part.
    wire signed [16:0] r_scaled = ($signed({1'b0, r}) * $signed({1'b0, GAIN})) >>> 6;
    wire signed [16:0] g_scaled = ($signed({1'b0, g}) * $signed({1'b0, GAIN})) >>> 6;
    wire signed [16:0] b_scaled = ($signed({1'b0, b}) * $signed({1'b0, GAIN})) >>> 6;

    wire signed [16:0] r_biased = r_scaled + BIAS;
    wire signed [16:0] g_biased = g_scaled + BIAS;
    wire signed [16:0] b_biased = b_scaled + BIAS;

    // 3. Saturating clamp to [0, 255]
    //    If the value went negative, clamp to 0.
    //    If it overflowed past 255, clamp to 255.
    wire [7:0] r_out = r_biased[16] ? 8'd0 : (r_biased > 17'sd255) ? 8'd255 : r_biased[7:0];
    wire [7:0] g_out = g_biased[16] ? 8'd0 : (g_biased > 17'sd255) ? 8'd255 : g_biased[7:0];
    wire [7:0] b_out = b_biased[16] ? 8'd0 : (b_biased > 17'sd255) ? 8'd255 : b_biased[7:0];

    // 4. Repack — alpha is always preserved
    assign m_axis_tdata = {a, b_out, g_out, r_out};

    // 5. Control signal pass-through (identical to rgba_to_gray)
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tuser  = s_axis_tuser;
    assign m_axis_tlast  = s_axis_tlast;

endmodule