`timescale 1ns/1ps

module brightness_top (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [23:0] rgb_pixel,
    input  wire        pixel_valid,
    input  wire [9:0]  pixel_x,
    input  wire [8:0]  pixel_y,

    input  wire [7:0]  bright_level,
    input  wire        bright_dir,

    output wire [7:0]  bright_out,
    output wire        bright_valid,
    output wire [9:0]  bright_x,
    output wire [8:0]  bright_y
);

wire [7:0] gray_out;
wire       gray_valid;
wire [9:0] gray_x;
wire [8:0] gray_y;

rgb24_to_gray8_brightness u_gray (
    .clk         (clk),
    .rst_n       (rst_n),
    .rgb_pixel   (rgb_pixel),
    .pixel_valid (pixel_valid),
    .pixel_x     (pixel_x),
    .pixel_y     (pixel_y),
    .gray_out    (gray_out),
    .gray_valid  (gray_valid),
    .gray_x      (gray_x),
    .gray_y      (gray_y)
);

brightness_controller u_bright (
    .clk         (clk),
    .rst_n       (rst_n),
    .gray_in     (gray_out),
    .gray_valid  (gray_valid),
    .gray_x      (gray_x),
    .gray_y      (gray_y),
    .bright_level(bright_level),
    .bright_dir  (bright_dir),
    .bright_out  (bright_out),
    .bright_valid(bright_valid),
    .bright_x    (bright_x),
    .bright_y    (bright_y)
);

endmodule