module img_pro_top (
    input wire clk,
    input wire rst_n,

    // AXI-Lite Signals (These come from the PS/Zynq)
    input  wire [31:0] s_axi_awaddr,        //write address -aw
    input  wire        s_axi_awvalid,       //
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,         //write data -w
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,         //write response -b
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    // ... add AR and R channels similarly ...

    // AXI-Stream (From/To VDMA)
    input  wire [23:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    output wire [23:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);

    // Wires to connect the Slave to the rest of the Top module
    wire [7:0] brightness_ctrl;
    wire [7:0] contrast_ctrl;

    // Instantiate the brain using the NEW clean name
    axi_lite_slave ctrl_unit (
        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(rst_n),
        
        // Connect all the standard AXI signals
        .S_AXI_AWADDR(s_axi_awaddr),        //ar - read address 
        // r - read data
        
        .S_AXI_AWVALID(s_axi_awvalid),
        .S_AXI_AWREADY(s_axi_awready),
        .S_AXI_WDATA(s_axi_wdata),
        .S_AXI_WSTRB(s_axi_wstrb),
        .S_AXI_WVALID(s_axi_wvalid),
        .S_AXI_WREADY(s_axi_wready),
        .S_AXI_BRESP(s_axi_bresp),
        .S_AXI_BVALID(s_axi_bvalid),
        .S_AXI_BREADY(s_axi_bready),
        // ... (Include AR and R channel connections here) ...

        // YOUR CUSTOM OUTPUTS
        .brightness_val(brightness_ctrl),
        .contrast_val(contrast_ctrl)
    );

    // For now, let's keep the loopback
    assign m_axis_tdata  = s_axis_tdata;
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;

endmodule