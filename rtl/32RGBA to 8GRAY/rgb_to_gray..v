module rgba_to_gray (
    // Slave Interface (Input)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,

    // Master Interface (Output)
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tuser,
    output wire        m_axis_tlast
);

    // 1. Unpack the bytes
    // Using the mapping: [31:24]=A, [23:16]=B, [15:8]=G, [7:0]=R
    wire [7:0] r = s_axis_tdata[7:0];
    wire [7:0] g = s_axis_tdata[15:8];
    wire [7:0] b = s_axis_tdata[23:16];
    wire [7:0] a = s_axis_tdata[31:24]; 

    // 2. The Grayscale Math
    wire [15:0] gray_sum = (r * 8'd77) + (g * 8'd150) + (b * 8'd29);
    wire [7:0]  gray     = gray_sum[15:8]; 

    // 3. Pack it back into 32-bits for the VDMA
    // We put 'gray' in R, G, and B. We keep 'a' as it was.
    assign m_axis_tdata = {a, gray, gray, gray};

    // 4. Control signal pass-through
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tuser  = s_axis_tuser;
    assign m_axis_tlast  = s_axis_tlast;

endmodule