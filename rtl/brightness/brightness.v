//module brightness_ctrl (
//    input  wire [7:0]  brightness_offset,
    
//    input  wire [31:0] s_axis_tdata,
//    input  wire        s_axis_tvalid,
//    output wire        s_axis_tready,
//    input  wire        s_axis_tuser,
//    input  wire        s_axis_tlast,

//    output wire [31:0] m_axis_tdata,
//    output wire        m_axis_tvalid,
//    input  wire        m_axis_tready,
//    output wire        m_axis_tuser,
//    output wire        m_axis_tlast
//);

//    // 1. Unpack the bytes
//    wire [7:0] r = s_axis_tdata[7:0];
//    wire [7:0] g = s_axis_tdata[15:8];
//    wire [7:0] b = s_axis_tdata[23:16];
//    wire [7:0] a = s_axis_tdata[31:24];

//    // 2. Math with Saturation (Clamping)
//    wire [8:0] r_sum = r + brightness_offset;
//    wire [7:0] r_out = (r_sum[8]) ? 8'hFF : r_sum[7:0];

//    wire [8:0] g_sum = g + brightness_offset;
//    wire [7:0] g_out = (g_sum[8]) ? 8'hFF : g_sum[7:0];

//    wire [8:0] b_sum = b + brightness_offset;
//    wire [7:0] b_out = (b_sum[8]) ? 8'hFF : b_sum[7:0];

//    // 3. Pack it back up (Alpha stays the same)
//    assign m_axis_tdata = {a, b_out, g_out, r_out};

//    // 4. Passthrough Control Signals
//    assign m_axis_tvalid = s_axis_tvalid;
//    assign s_axis_tready = m_axis_tready;
//    assign m_axis_tuser  = s_axis_tuser;
//    assign m_axis_tlast  = s_axis_tlast;

//endmodule
///////////////////////reparing slack
module brightness_ctrl (
    input  wire        clk,               // ADDED: Clock for pipelining
    input  wire        rst_n,             // ADDED: Reset
    input  wire [7:0]  brightness_offset,
    
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,

    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tuser,
    output wire        m_axis_tlast
);

    // 1. Unpack the bytes (Still wires)
    wire [7:0] r = s_axis_tdata[7:0];
    wire [7:0] g = s_axis_tdata[15:8];
    wire [7:0] b = s_axis_tdata[23:16];
    wire [7:0] a = s_axis_tdata[31:24];

    // 2. Intermediate Math (Still wires)
    wire [8:0] r_sum = r + brightness_offset;
    wire [7:0] r_out = (r_sum[8]) ? 8'hFF : r_sum[7:0];

    wire [8:0] g_sum = g + brightness_offset;
    wire [7:0] g_out = (g_sum[8]) ? 8'hFF : g_sum[7:0];

    wire [8:0] b_sum = b + brightness_offset;
    wire [7:0] b_out = (b_sum[8]) ? 8'hFF : b_sum[7:0];

    // 3. PIPELINE REGISTERS
    // These "break" the connection between Brightness math and Contrast math
    reg [31:0] m_tdata_reg;
    reg        m_tvalid_reg;
    reg        m_tuser_reg;
    reg        m_tlast_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            m_tdata_reg  <= 32'd0;
            m_tvalid_reg <= 1'b0;
            m_tuser_reg  <= 1'b0;
            m_tlast_reg  <= 1'b0;
        end else if (m_axis_tready) begin
            // We capture the math result into a register on every clock edge
            m_tdata_reg  <= {a, b_out, g_out, r_out};
            m_tvalid_reg <= s_axis_tvalid;
            m_tuser_reg  <= s_axis_tuser;
            m_tlast_reg  <= s_axis_tlast;
        end
    end

    // 4. Connect registers to outputs
    assign m_axis_tdata  = m_tdata_reg;
    assign m_axis_tvalid = m_tvalid_reg;
    assign m_axis_tuser  = m_tuser_reg;
    assign m_axis_tlast  = m_tlast_reg;
    
    // Ready can stay combinatorial to avoid stalling the pipeline
    assign s_axis_tready = m_axis_tready;

endmodule