// rgb24_to_gray8.v
// Wrapper - unpacks 24-bit RGB bus and feeds core converter

module rgb24_to_gray8 (
    input  wire        clk,
    input  wire        rst_n,

    // 24-bit packed RGB input
    input  wire [23:0] rgb_pixel,     // [23:16]=R [15:8]=G [7:0]=B
    input  wire        pixel_valid,
    input  wire [9:0]  pixel_x,
    input  wire [8:0]  pixel_y,

    // 8-bit grayscale output
    output wire [7:0]  gray_out,
    output wire        gray_valid,
    output wire [9:0]  gray_x,
    output wire [8:0]  gray_y
);

// ─── Unpack RGB ───────────────────────────────────────────────
wire [7:0] r = rgb_pixel[23:16];
wire [7:0] g = rgb_pixel[15:8];
wire [7:0] b = rgb_pixel[7:0];


rgb_to_gray u_rgb_to_gray (
    .clk         (clk),
    .rst_n       (rst_n),
    .pixel_r     (r),
    .pixel_g     (g),
    .pixel_b     (b),
    .pixel_valid (pixel_valid),
    .pixel_x     (pixel_x),
    .pixel_y     (pixel_y),
    .gray_out    (gray_out),
    .gray_valid  (gray_valid),
    .gray_x      (gray_x),
    .gray_y      (gray_y)
);

endmodule