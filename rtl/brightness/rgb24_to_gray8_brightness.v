`timescale 1ns/1ps

module rgb24_to_gray8_brightness (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [23:0] rgb_pixel,
    input  wire        pixel_valid,
    input  wire [9:0]  pixel_x,
    input  wire [8:0]  pixel_y,

    output reg  [7:0]  gray_out,
    output reg         gray_valid,
    output reg  [9:0]  gray_x,
    output reg  [8:0]  gray_y
);

wire [7:0] r;
wire [7:0] g;
wire [7:0] b;

wire [15:0] gray_sum;

assign r = rgb_pixel[23:16];
assign g = rgb_pixel[15:8];
assign b = rgb_pixel[7:0];

assign gray_sum = (r * 8'd77) + (g * 8'd150) + (b * 8'd29);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray_out   <= 8'd0;
        gray_valid <= 1'b0;
        gray_x     <= 10'd0;
        gray_y     <= 9'd0;
    end
    else begin
        gray_valid <= pixel_valid;
        gray_x     <= pixel_x;
        gray_y     <= pixel_y;

        if (pixel_valid)
            gray_out <= gray_sum[15:8];
    end
end

endmodule