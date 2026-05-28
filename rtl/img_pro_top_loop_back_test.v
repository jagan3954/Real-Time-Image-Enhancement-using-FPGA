module img_pro_top_loop_back_test(
    input wire clk,
    input wire rst_n,
    
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tuser,   
    output wire        s_axis_tready,

    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    output wire        m_axis_tlast,
    output wire        m_axis_tuser,   
    input  wire        m_axis_tready
);
// =========================================================
    // 1. Control Wires (From AXI-Lite Slave)
    // =========================================================
    wire [7:0]  brightness_ctrl;
    wire [7:0]  min_val_ctrl;
    wire [15:0] scale_factor_ctrl;

    // =========================================================
    // 2. Pipeline "Glue" Wires (The data highway)
    // =========================================================
    
    // Grayscale -> Noise Filter
    wire [31:0] gray_tdata;
    wire        gray_tvalid, gray_tready, gray_tuser, gray_tlast;

    // Noise Filter -> Brightness (YOU NEED TO ADD THIS SET)
    wire [31:0] noise_tdata;
    wire        noise_tvalid, noise_tready, noise_tuser, noise_tlast;

    // Brightness -> Contrast
    wire [31:0] bright_tdata;
    wire        bright_tvalid, bright_tready, bright_tuser, bright_tlast;

    // Contrast -> Sobel Edge Detection
    wire [31:0] contrast_tdata;
    wire        contrast_tvalid, contrast_tready, contrast_tuser, contrast_tlast;
    
    ///out 
    wire [31:0] sobel_out_tdata;
    wire        sobel_out_tvalid, sobel_out_tready, sobel_out_tuser, sobel_out_tlast;

    axi_lite_slave ctrl_unit (
        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETN (rst_n),
        .S_AXI_AWADDR  (s_axi_awaddr),
        .S_AXI_AWVALID (s_axi_awvalid),
        .S_AXI_AWREADY (s_axi_awready),
        .S_AXI_WDATA   (s_axi_wdata),
        .S_AXI_WSTRB   (s_axi_wstrb),
        .S_AXI_WVALID  (s_axi_wvalid),
        .S_AXI_WREADY  (s_axi_wready),
        .S_AXI_BRESP   (s_axi_bresp),
        .S_AXI_BVALID  (s_axi_bvalid),
        .S_AXI_BREADY  (s_axi_bready),
        .S_AXI_ARADDR  (s_axi_araddr),
        .S_AXI_ARVALID (s_axi_arvalid),
        .S_AXI_ARREADY (s_axi_arready),
        .S_AXI_RDATA   (s_axi_rdata),
        .S_AXI_RRESP   (s_axi_rresp),
        .S_AXI_RVALID  (s_axi_rvalid),
        .S_AXI_RREADY  (s_axi_rready),
        .brightness_val(brightness_ctrl),
        //.contrast_val  (contrast_ctrl)
        // Inside axi_lite_slave ctrl_unit (...)
// Replace .contrast_val(...) with:
        .min_val      (min_val_ctrl),
        .scale_factor (scale_factor_ctrl)
    );
//111111
//    rgba_to_gray u_grayscale_unit (
//        .s_axis_tdata  (s_axis_tdata),
//        .s_axis_tvalid (s_axis_tvalid),
//        .s_axis_tready (s_axis_tready), 
//        .s_axis_tuser  (s_axis_tuser),
//        .s_axis_tlast  (s_axis_tlast),
        
//        .m_axis_tdata  (gray_tdata),
//        .m_axis_tvalid (gray_tvalid),
//        .m_axis_tready (gray_tready),
//        .m_axis_tuser  (gray_tuser),
//        .m_axis_tlast  (gray_tlast)
//    );
//////////////////////////////1
rgba_to_ycbcr u_ycbcr_entrance (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .s_axis_tuser  (s_axis_tuser),
        .s_axis_tlast  (s_axis_tlast),
        
        .m_axis_tdata  (gray_tdata), // We keep this wire name to avoid renaming everything
        .m_axis_tvalid (gray_tvalid),
        .m_axis_tready (gray_tready),
        .m_axis_tuser  (gray_tuser),
        .m_axis_tlast  (gray_tlast)
    );
    // 2. Noise Filter (Input from gray_* -> Output to noise_*)
    noise_filter #( .IMG_WIDTH(640) ) u_noise_unit (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata  (gray_tdata),
        .s_axis_tvalid (gray_tvalid),
        .s_axis_tready (gray_tready),
        .s_axis_tuser  (gray_tuser),
        .s_axis_tlast  (gray_tlast),
        .m_axis_tdata  (noise_tdata),
        .m_axis_tvalid (noise_tvalid),
        .m_axis_tready (noise_tready),
        .m_axis_tuser  (noise_tuser),
        .m_axis_tlast  (noise_tlast)
    );
    
    brightness_ctrl u_brightness_unit (
    .clk           (clk),    // <--- ARE THESE HERE?
        .rst_n         (rst_n),  // <--- AND THIS?
      //  .brightness    (brightness_ctrl),
        // ... rest of the wires
        .brightness_offset (brightness_ctrl), 
        
       .s_axis_tdata  (noise_tdata),
        .s_axis_tvalid (noise_tvalid),
        .s_axis_tready (noise_tready),
        .s_axis_tuser  (noise_tuser),
        .s_axis_tlast  (noise_tlast),
        
        
.m_axis_tdata  (bright_tdata),
.m_axis_tvalid (bright_tvalid),
.m_axis_tready (bright_tready),
.m_axis_tuser  (bright_tuser),
.m_axis_tlast  (bright_tlast)
    );
    
    
    kontrast u_contrast_unit (
    .clk           (clk),   // Connect to top-level clk
    .rst_n         (rst_n), // Connect to top-level rst_n
    .min_val       (min_val_ctrl),
    .scale_factor  (scale_factor_ctrl),
 
    
    // Input from Brightness module
    .s_axis_tdata  (bright_tdata),
    .s_axis_tvalid (bright_tvalid),
    .s_axis_tready (bright_tready),
    .s_axis_tuser  (bright_tuser),
    .s_axis_tlast  (bright_tlast),
    
//    // Output to Final Top-Level Pins
//    .m_axis_tdata  (m_axis_tdata),
//    .m_axis_tvalid (m_axis_tvalid),
//    .m_axis_tready (m_axis_tready),
//    .m_axis_tuser  (m_axis_tuser),
//    .m_axis_tlast  (m_axis_tlast)

// TO THIS (Connected to your new intermediate wires)
.m_axis_tdata  (contrast_tdata),
.m_axis_tvalid (contrast_tvalid),
.m_axis_tready (contrast_tready),
.m_axis_tuser  (contrast_tuser),
.m_axis_tlast  (contrast_tlast)
);


///////5555555555
sobel_edge #( .IMG_WIDTH(640) ) u_sobel_unit (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata  (contrast_tdata),
        .s_axis_tvalid (contrast_tvalid),
        .s_axis_tready (contrast_tready),
        .s_axis_tuser  (contrast_tuser),
        .s_axis_tlast  (contrast_tlast),
        
        // Final exit out to the board pins!
//        .m_axis_tdata  (m_axis_tdata),
//        .m_axis_tvalid (m_axis_tvalid),
//        .m_axis_tready (m_axis_tready),
//        .m_axis_tuser  (m_axis_tuser),
//        .m_axis_tlast  (m_axis_tlast)
// Inside u_sobel_unit
    .m_axis_tdata  (sobel_out_tdata),
    .m_axis_tvalid (sobel_out_tvalid),
    .m_axis_tready (sobel_out_tready),
    .m_axis_tuser  (sobel_out_tuser),
    .m_axis_tlast  (sobel_out_tlast)
    );
    //////////////////////
ycbcr_to_rgba u_rgba_exit (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axis_tdata  (sobel_out_tdata),
        .s_axis_tvalid (sobel_out_tvalid),
        .s_axis_tready (sobel_out_tready),
        .s_axis_tuser  (sobel_out_tuser),
        .s_axis_tlast  (sobel_out_tlast),
        
        .m_axis_tdata  (m_axis_tdata),   // Final exit to board pins!
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready),
        .m_axis_tuser  (m_axis_tuser),
        .m_axis_tlast  (m_axis_tlast)
    );

endmodule
