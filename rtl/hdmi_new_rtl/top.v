`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 11:47:27
// Design Name: 
// Module Name: vga_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module vga_top(
    input  wire sys_clk_in,
    input  wire sys_rst_in,
    output wire hdmi_clk_n,
    output wire hdmi_clk_p,
    output wire [2:0] hdmi_tx_n,
    output wire [2:0] hdmi_tx_p
);

    wire clk_25mhz, clk_125mhz, clk_locked;
    wire vga_hsync, vga_vsync, vga_video_on;
    wire vga_reset = sys_rst_in;

    wire [9:0] pixel_x, pixel_y;
    wire [16:0] pixel_addr;
    wire [7:0]  pixel_data;

    // Clock wizard - generates 25MHz and 125MHz
    clk_wiz_1 clk_inst (
        .clk_out1 (clk_25mhz),
        .clk_out2 (clk_125mhz),
        .reset    (vga_reset),
        .locked   (clk_locked),
        .clk_in1  (sys_clk_in)
    );

    // VGA timing - gives us x,y coordinates each pixel clock
    vga_ctrl vga_inst (
        .clk25    (clk_25mhz),
        .rst      (~clk_locked),
        .hsync    (vga_hsync),
        .vsync    (vga_vsync),
        .video_on (vga_video_on),
        .x        (pixel_x),
        .y        (pixel_y)
    );

    // Address: scale 640x480 display down to 320x240 image
    assign pixel_addr = (pixel_y[9:1]) * 320 + pixel_x[9:1];

    // BRAM holding your image
    image_rom rom_inst (
        .clk  (clk_25mhz),
        .addr (pixel_addr),
        .dout (pixel_data)
    );

    // Grayscale pixel -> RGB (same value on all 3 channels)
    wire [7:0] red   = vga_video_on ? pixel_data : 8'h00;
    wire [7:0] green = vga_video_on ? pixel_data : 8'h00;
    wire [7:0] blue  = vga_video_on ? pixel_data : 8'h00;

    // // HDMI TX IP - encodes to TMDS and drives the HDMI pins
    // hdmi_tx_0 vga_to_hdmi_inst (
    //     .pix_clk       (clk_25mhz),
    //     .pix_clkx5     (clk_125mhz),
    //     .pix_clk_locked(clk_locked),
    //     .rst           (vga_reset),
    //     .red           (red),
    //     .green         (green),
    //     .blue          (blue),
    //     .hsync         (vga_hsync),
    //     .vsync         (vga_vsync),
    //     .vde           (vga_video_on),
    //     .aux0_din      (4'b0),
    //     .aux1_din      (4'b0),
    //     .aux2_din      (4'b0),
    //     .ade           (1'b0),
    //     .TMDS_CLK_P    (hdmi_clk_p),
    //     .TMDS_CLK_N    (hdmi_clk_n),
    //     .TMDS_DATA_P   (hdmi_tx_p),
    //     .TMDS_DATA_N   (hdmi_tx_n)
    // );

hdmi_tx_0 vga_to_hdmi_inst (
    .pix_clk        (clk_25mhz),
    .pix_clkx5      (clk_125mhz),
    .pix_clk_locked (clk_locked),
    .rst            (vga_reset),
    .red            (red),
    .green          (green),
    .blue           (blue),
    .hsync          (vga_hsync),
    .vsync          (vga_vsync),
    .vde            (vga_video_on),
    .TMDS_CLK_P     (hdmi_clk_p),
    .TMDS_CLK_N     (hdmi_clk_n),
    .TMDS_DATA_P    (hdmi_tx_p),
    .TMDS_DATA_N    (hdmi_tx_n)
);
endmodule
