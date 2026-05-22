`timescale 1ns/1ps

module tb_image_enhancement;

logic        clk;
logic        rst_n;

logic [23:0] rgb_pixel;
logic        pixel_valid;
logic [9:0]  pixel_x;
logic [8:0]  pixel_y;

logic [7:0]  bright_level;
logic        bright_dir;
logic [7:0]  contrast_level;

logic [7:0]  contrast_out;
logic        contrast_valid;
logic [9:0]  contrast_x;
logic [8:0]  contrast_y;

image_enhancement_top dut (
    .clk            (clk),
    .rst_n          (rst_n),

    .rgb_pixel      (rgb_pixel),
    .pixel_valid    (pixel_valid),
    .pixel_x        (pixel_x),
    .pixel_y        (pixel_y),

    .bright_level   (bright_level),
    .bright_dir     (bright_dir),
    .contrast_level (contrast_level),

    .contrast_out   (contrast_out),
    .contrast_valid (contrast_valid),
    .contrast_x     (contrast_x),
    .contrast_y     (contrast_y)
);

always #5 clk = ~clk;

task automatic send_pixel (
    input logic [7:0] r,
    input logic [7:0] g,
    input logic [7:0] b,
    input logic [9:0] x,
    input logic [8:0] y,
    input logic [7:0] b_level,
    input logic       b_dir,
    input logic [7:0] c_level
);
    begin
        rgb_pixel      = {r, g, b};
        pixel_x        = x;
        pixel_y        = y;
        bright_level   = b_level;
        bright_dir     = b_dir;
        contrast_level = c_level;
        pixel_valid    = 1'b1;

        @(posedge clk);
        pixel_valid = 1'b0;

        repeat(6) @(posedge clk);
    end
endtask

always @(posedge clk) begin
    if (contrast_valid) begin
        $display("Time=%0t | X=%0d Y=%0d | Contrast Output=%0d",
                 $time, contrast_x, contrast_y, contrast_out);
    end
end

initial begin
    clk            = 1'b0;
    rst_n          = 1'b0;

    rgb_pixel      = 24'h000000;
    pixel_valid    = 1'b0;
    pixel_x        = 10'd0;
    pixel_y        = 9'd0;

    bright_level   = 8'd0;
    bright_dir     = 1'b1;
    contrast_level = 8'd0;

    repeat(4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    send_pixel(8'd128, 8'd128, 8'd128, 10'd0,  9'd0, 8'd50,  1'b1, 8'd20);
    send_pixel(8'd50,  8'd50,  8'd50,  10'd1,  9'd0, 8'd100, 1'b1, 8'd30);
    send_pixel(8'd220, 8'd220, 8'd220, 10'd2,  9'd0, 8'd50,  1'b1, 8'd40);
    send_pixel(8'd255, 8'd255, 8'd255, 10'd3,  9'd0, 8'd100, 1'b1, 8'd50);

    send_pixel(8'd128, 8'd128, 8'd128, 10'd4,  9'd0, 8'd50,  1'b0, 8'd20);
    send_pixel(8'd220, 8'd180, 8'd160, 10'd5,  9'd0, 8'd100, 1'b0, 8'd30);
    send_pixel(8'd20,  8'd20,  8'd20,  10'd6,  9'd0, 8'd50,  1'b0, 8'd40);
    send_pixel(8'd0,   8'd0,   8'd0,   10'd7,  9'd0, 8'd100, 1'b0, 8'd50);

    send_pixel(8'd100, 8'd150, 8'd200, 10'd8,  9'd0, 8'd0,   1'b1, 8'd30);
    send_pixel(8'd255, 8'd0,   8'd0,   10'd9,  9'd0, 8'd30,  1'b1, 8'd20);
    send_pixel(8'd0,   8'd255, 8'd0,   10'd10, 9'd0, 8'd30,  1'b0, 8'd20);
    send_pixel(8'd0,   8'd0,   8'd255, 10'd11, 9'd0, 8'd200, 1'b1, 8'd30);

    repeat(10) @(posedge clk);

    $finish;
end

endmodule