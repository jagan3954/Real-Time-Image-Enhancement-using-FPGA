// module contrast_enhance (
//
//     input  wire [31:0] s_axis_tdata,
//     input  wire        s_axis_tvalid,
//     output wire        s_axis_tready,
//     input  wire        s_axis_tuser,
//     input  wire        s_axis_tlast,
//
//     output wire [31:0] m_axis_tdata,
//     output wire        m_axis_tvalid,
//     input  wire        m_axis_tready,
//     output wire        m_axis_tuser,
//     output wire        m_axis_tlast
// );
//
//     parameter [7:0]  GAIN  = 8'd96;
//     parameter signed [8:0] BIAS = -9'sd32;
//
//
//     wire [7:0] r = s_axis_tdata[7:0];
//     wire [7:0] g = s_axis_tdata[15:8];
//     wire [7:0] b = s_axis_tdata[23:16];
//     wire [7:0] a = s_axis_tdata[31:24];
//
//
//     wire signed [16:0] r_scaled = ($signed({1'b0, r}) * $signed({1'b0, GAIN})) >>> 6;
//     wire signed [16:0] g_scaled = ($signed({1'b0, g}) * $signed({1'b0, GAIN})) >>> 6;
//     wire signed [16:0] b_scaled = ($signed({1'b0, b}) * $signed({1'b0, GAIN})) >>> 6;
//
//     wire signed [16:0] r_biased = r_scaled + BIAS;
//     wire signed [16:0] g_biased = g_scaled + BIAS;
//     wire signed [16:0] b_biased = b_scaled + BIAS;
//
//
//     wire [7:0] r_out = r_biased[16] ? 8'd0 : (r_biased > 17'sd255) ? 8'd255 : r_biased[7:0];
//     wire [7:0] g_out = g_biased[16] ? 8'd0 : (g_biased > 17'sd255) ? 8'd255 : g_biased[7:0];
//     wire [7:0] b_out = b_biased[16] ? 8'd0 : (b_biased > 17'sd255) ? 8'd255 : b_biased[7:0];
//
//
//     assign m_axis_tdata = {a, b_out, g_out, r_out};
//
//
//     assign m_axis_tvalid = s_axis_tvalid;
//     assign s_axis_tready = m_axis_tready;
//     assign m_axis_tuser  = s_axis_tuser;
//     assign m_axis_tlast  = s_axis_tlast;
//
// endmodule

// module kontrast (
//     input wire [7:0]min_val,max_val,

//     input  wire [31:0] s_axis_tdata,
//     input  wire        s_axis_tvalid,
//     output wire        s_axis_tready,
//     input  wire        s_axis_tuser,
//     input  wire        s_axis_tlast,

//     output wire [31:0] m_axis_tdata,
//     output wire        m_axis_tvalid,
//     input  wire        m_axis_tready,
//     output wire        m_axis_tuser,
//     output wire        m_axis_tlast

// );
//  wire [7:0] pixel_in = s_axis_tdata[7:0];
//  wire [7:0] sub_res = (pixel_in <= min_val)?8'd0:(pixel_in-min_val);
//  wire [7:0] stretched_res = sub_res;
//  assign m_axis_tdata = {8'hff,stretched_res,stretched_res,stretched_res};

//     assign m_axis_tvalid = s_axis_tvalid;
//     assign s_axis_tready = m_axis_tready;
//     assign m_axis_tlast  = s_axis_tlast;
//     assign m_axis_tuser  = s_axis_tuser;

// endmodule

// module kontrast (
//     input  wire [7:0]  min_val,
//     input  wire [15:0] scale_factor,  // Q8.8 fixed point, sent from Python
//
//     input  wire [31:0] s_axis_tdata,
//     input  wire        s_axis_tvalid,
//     output wire        s_axis_tready,
//     input  wire        s_axis_tuser,
//     input  wire        s_axis_tlast,
//
//     output wire [31:0] m_axis_tdata,
//     output wire        m_axis_tvalid,
//     input  wire        m_axis_tready,
//     output wire        m_axis_tuser,
//     output wire        m_axis_tlast
// );
//
//     wire [7:0] pixel_in = s_axis_tdata[7:0];
//
//     // Subtract min, clamp to 0
//     wire [8:0] sub_res  = (pixel_in > min_val) ? (pixel_in - min_val) : 9'd0;
//
//     // Multiply by scale factor (Q8.8), take upper 8 bits
//     wire [23:0] scaled  = sub_res * scale_factor;
//     wire [7:0]  pixel_out = (scaled[23:8] > 255) ? 8'd255 : scaled[15:8];
//
//     assign m_axis_tdata  = {8'hff, pixel_out, pixel_out, pixel_out};
//     assign m_axis_tvalid = s_axis_tvalid;
//     assign s_axis_tready = m_axis_tready;
//     assign m_axis_tlast  = s_axis_tlast;
//     assign m_axis_tuser  = s_axis_tuser;
//
// endmodule
module kontrast (
    // Control signals from AXI-Lite
    input  wire [7:0]  min_val,
    input  wire [15:0] scale_factor,  // Q8.8 fixed point (calculated in Python)

    // AXI-Stream Slave (Input)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,

    // AXI-Stream Master (Output)
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tuser,
    output wire        m_axis_tlast
);

    // 1. Extract the grayscale pixel (R, G, and B are same)
    wire [7:0] pixel_in = s_axis_tdata[7:0];

    // 2. Step 1: Subtraction (Input - Min)
    // We use 9 bits to prevent underflow issues before the ternary check
    wire [8:0] sub_res = (pixel_in > min_val) ? (pixel_in - min_val) : 9'd0;

    // 3. Step 2: Multiplication (sub_res * scale_factor)
    // 9-bit * 16-bit = 25-bit result
    wire [24:0] scaled = sub_res * scale_factor;

    // 4. Step 3: Shift and Clamp
    // Since scale_factor is Q8.8, we divide by 256 by taking bits [24:8]
    // If any bits above the lower 8 (bits 24:16) are non-zero, it's an overflow (> 255)
    wire [7:0] pixel_out;
    assign pixel_out = (scaled[24:16] != 0) ? 8'hFF : scaled[15:8];

    // 5. Reconstruct the RGBA data (Alpha remains 0xFF)
    assign m_axis_tdata  = {8'hFF, pixel_out, pixel_out, pixel_out};

    // 6. Pass-through Control Signals (Zero Latency)
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tlast  = s_axis_tlast;
    assign m_axis_tuser  = s_axis_tuser;

endmodule
