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

    wire [7:0] brightness_ctrl;
   // wire [7:0] contrast_ctrl;
    
    wire [31:0] gray_tdata;
    wire        gray_tvalid;
    wire        gray_tready;
    wire        gray_tuser;
    wire        gray_tlast;
 ////////   
    // 1. New Control Wires
wire [7:0]  min_val_ctrl;
wire [15:0] scale_factor_ctrl;

// 2. New Pipeline Wires (Between Brightness and Contrast)
wire [31:0] bright_tdata;
wire        bright_tvalid;
wire        bright_tready;
wire        bright_tuser;
wire        bright_tlast;
///////////
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

    rgba_to_gray u_grayscale_unit (
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready), 
        .s_axis_tuser  (s_axis_tuser),
        .s_axis_tlast  (s_axis_tlast),
        
        
        .m_axis_tdata  (gray_tdata),
        .m_axis_tvalid (gray_tvalid),
        .m_axis_tready (gray_tready),
        .m_axis_tuser  (gray_tuser),
        .m_axis_tlast  (gray_tlast)
    );

    
    brightness_ctrl u_brightness_unit (
        .brightness_offset (brightness_ctrl), 
        
       
        .s_axis_tdata  (gray_tdata),
        .s_axis_tvalid (gray_tvalid),
        .s_axis_tready (gray_tready),
        .s_axis_tuser  (gray_tuser),
        .s_axis_tlast  (gray_tlast),
        
        
//        .m_axis_tdata  (m_axis_tdata),
//        .m_axis_tvalid (m_axis_tvalid),
//        .m_axis_tready (m_axis_tready),
//        .m_axis_tuser  (m_axis_tuser),
//        .m_axis_tlast  (m_axis_tlast)
        // Inside brightness_ctrl u_brightness_unit (...)
// Change the m_axis_* mappings to:
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
    
    // Output to Final Top-Level Pins
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready),
    .m_axis_tuser  (m_axis_tuser),
    .m_axis_tlast  (m_axis_tlast)
);


endmodule
