`timescale 1ns/1ps

module tb_rgb24_to_gray8;

logic        clk   = 0;
logic        rst_n = 0;
always #5    clk   = ~clk;    


logic [23:0] rgb_pixel;
logic        pixel_valid;
logic [9:0]  pixel_x;
logic [8:0]  pixel_y;


logic [7:0]  gray_out;
logic        gray_valid;
logic [9:0]  gray_x;
logic [8:0]  gray_y;


rgb24_to_gray8 dut (
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


task automatic send_pixel (
    input logic [7:0] r, g, b,
    input logic [9:0] x,
    input logic [8:0] y
);
    real expected;

    rgb_pixel   = {r, g, b};
    pixel_x     = x;
    pixel_y     = y;
    pixel_valid = 1'b1;

    @(posedge clk);
    pixel_valid = 1'b0;

    repeat(3) @(posedge clk);

    expected = (0.299 * real'(r)) +
               (0.587 * real'(g)) +
               (0.114 * real'(b));

   
endtask

initial begin
    
    rst_n       = 1'b0;
    rgb_pixel   = 24'h000000;
    pixel_valid = 1'b0;
    pixel_x     = 10'd0;
    pixel_y     = 9'd0;

   

    
    repeat(4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    
    send_pixel(255, 255, 255, 10'd0, 9'd0);  
    send_pixel(0,   0,   0,   10'd1, 9'd0);  
    send_pixel(255, 0,   0,   10'd2, 9'd0);  
    send_pixel(0,   255, 0,   10'd3, 9'd0);  
    send_pixel(0,   0,   255, 10'd4, 9'd0);  
    send_pixel(128, 128, 128, 10'd5, 9'd0);  
    send_pixel(200, 150, 100, 10'd6, 9'd0);  
    send_pixel(75,  180, 210, 10'd7, 9'd0); 

   
    $finish;
end


endmodule