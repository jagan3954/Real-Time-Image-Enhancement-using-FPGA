module top (
    input  wire        clk_in,
    input  wire        rst_btn,
    output wire        hdmi_clk_p,
    output wire        hdmi_clk_n,
    output wire [2:0]  hdmi_d_p,
    output wire [2:0]  hdmi_d_n
);

wire pclk;
wire pclk_5x;
wire locked;

clk_wiz_0 clk_gen (
    .clk_in1  (clk_in),
    .clk_out1 (pclk),
    .clk_out2 (pclk_5x),
    .locked   (locked),
    .reset    (rst_btn)
);

wire rst_n = locked;

wire [23:0] vid_data;
wire        vid_hsync;
wire        vid_vsync;
wire        vid_de;

test_pattern_gen tpg (
    .pclk   (pclk),
    .rst_n  (rst_n),
    .hSync  (vid_hsync),
    .vSync  (vid_vsync),
    .de     (vid_de),
    .rgb    (vid_data)
);

rgb2dvi #(
    .kGenerateSerialClk (1'b0),
    .kClkRange          (2)
) hdmi_out (
    .TMDS_Clk_p  (hdmi_clk_p),
    .TMDS_Clk_n  (hdmi_clk_n),
    .TMDS_Data_p (hdmi_d_p),
    .TMDS_Data_n (hdmi_d_n),
    .aRst_n      (rst_n),
    .vid_pData   (vid_data),
    .vid_pVDE    (vid_de),
    .vid_pHSync  (vid_hsync),
    .vid_pVSync  (vid_vsync),
    .PixelClk    (pclk),
    .SerialClk   (pclk_5x)
);

endmodule