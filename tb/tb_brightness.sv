`timescale 1ns/1ps

module tb_brightness;

logic        clk   = 0;
logic        rst_n = 0;
always #5    clk   = ~clk;

logic [23:0] rgb_pixel;
logic        pixel_valid;
logic [9:0]  pixel_x;
logic [8:0]  pixel_y;
logic [7:0]  bright_level;
logic        bright_dir;

logic [7:0]  bright_out;
logic        bright_valid;
logic [9:0]  bright_x;
logic [8:0]  bright_y;

brightness_top dut (
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

task automatic send_pixel (
    input logic [7:0] r, g, b,
    input logic [9:0] x,
    input logic [8:0] y,
    input logic [7:0] level,
    input logic       direction
);
    begin
        bright_level = level;
        bright_dir   = direction;
        rgb_pixel    = {r, g, b};
        pixel_x      = x;
        pixel_y      = y;
        pixel_valid  = 1'b1;

        @(posedge clk);
        pixel_valid = 1'b0;

        repeat(4) @(posedge clk);
    end
endtask

initial begin
    rst_n        = 1'b0;
    rgb_pixel    = 24'h000000;
    pixel_valid  = 1'b0;
    pixel_x      = 10'd0;
    pixel_y      = 9'd0;
    bright_level = 8'd0;
    bright_dir   = 1'b1;

    repeat(4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    send_pixel(128, 128, 128, 10'd0, 9'd0, 8'd50,  1'b1);
    send_pixel(50,  50,  50,  10'd1, 9'd0, 8'd100, 1'b1);
    send_pixel(220, 220, 220, 10'd2, 9'd0, 8'd50,  1'b1);
    send_pixel(255, 255, 255, 10'd3, 9'd0, 8'd100, 1'b1);
    send_pixel(128, 128, 128, 10'd4, 9'd0, 8'd50,  1'b0);
    send_pixel(220, 180, 160, 10'd5, 9'd0, 8'd100, 1'b0);
    send_pixel(20,  20,  20,  10'd6, 9'd0, 8'd50,  1'b0);
    send_pixel(0,   0,   0,   10'd7, 9'd0, 8'd100, 1'b0);
    send_pixel(100, 150, 200, 10'd8, 9'd0, 8'd0,   1'b1);
    send_pixel(100, 150, 200, 10'd9, 9'd0, 8'd0,   1'b0);
    send_pixel(255, 0,   0,   10'd10, 9'd0, 8'd30, 1'b1);
    send_pixel(0,   255, 0,   10'd11, 9'd0, 8'd30, 1'b0);
    send_pixel(0,   0,   255, 10'd12, 9'd0, 8'd200,1'b1);

    $finish;
end

endmodule