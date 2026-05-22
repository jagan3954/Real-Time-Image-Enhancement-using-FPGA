`timescale 1ns/1ps

module image_enhancement_top (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [23:0] rgb_pixel,
    input  wire        pixel_valid,
    input  wire [9:0]  pixel_x,
    input  wire [8:0]  pixel_y,

    input  wire [7:0]  bright_level,
    input  wire        bright_dir,
    input  wire [7:0]  contrast_level,

    output wire [7:0]  contrast_out,
    output wire        contrast_valid,
    output wire [9:0]  contrast_x,
    output wire [8:0]  contrast_y
);

wire [7:0] bright_out;
wire       bright_valid;
wire [9:0] bright_x;
wire [8:0] bright_y;

brightness_top u_brightness (
    .clk         (clk),
    .rst_n       (rst_n),

    .rgb_pixel   (rgb_pixel),
    .pixel_valid (pixel_valid),
    .pixel_x     (pixel_x),
    .pixel_y     (pixel_y),

    .bright_level(bright_level),
    .bright_dir  (bright_dir),

    .bright_out  (bright_out),
    .bright_valid(bright_valid),
    .bright_x    (bright_x),
    .bright_y    (bright_y)
);

contrast_enhancement u_contrast (
    .clk           (clk),
    .rst_n         (rst_n),

    .pixel_in      (bright_out),
    .pixel_valid   (bright_valid),
    .pixel_x       (bright_x),
    .pixel_y       (bright_y),

    .contrast_level(contrast_level),

    .contrast_out  (contrast_out),
    .contrast_valid(contrast_valid),
    .contrast_x    (contrast_x),
    .contrast_y    (contrast_y)
);

endmodule