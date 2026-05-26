module noise_filter (
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream Slave
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,
    
    // AXI-Stream Master
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tuser,
    output reg         m_axis_tlast
);

    assign s_axis_tready = m_axis_tready;

    // Sliding Window Registers
    reg [7:0] p1, p2, p3; 
    reg [2:0] v_shift; // Valid shift register
    reg [2:0] l_shift; // Last shift register
    reg [2:0] u_shift; // User shift register

    // Fixed point multiplier for 1/3 (0.333 * 256 = 85)
    localparam [7:0] INV_3 = 8'd85; 

    wire [9:0] sum = p1 + p2 + p3;
    wire [17:0] scaled_sum = sum * INV_3;
    wire [7:0] avg = scaled_sum[15:8]; // Shift right by 8

    always @(posedge clk) begin
        if (!rst_n) begin
            {p1, p2, p3} <= 24'b0;
            v_shift <= 3'b0;
            l_shift <= 3'b0;
            u_shift <= 3'b0;
        end else if (m_axis_tready) begin
            // Shift pixels in
            p1 <= s_axis_tdata[7:0];
            p2 <= p1;
            p3 <= p2;
            
            // Shift control signals to stay synced with the data
            v_shift <= {v_shift[1:0], s_axis_tvalid};
            l_shift <= {l_shift[1:0], s_axis_tlast};
            u_shift <= {u_shift[1:0], s_axis_tuser};

            // Output the average
            m_axis_tdata  <= {8'hFF, avg, avg, avg};
            m_axis_tvalid <= v_shift[2];
            m_axis_tlast  <= l_shift[2];
            m_axis_tuser  <= u_shift[2];
        end
    end
endmodule
