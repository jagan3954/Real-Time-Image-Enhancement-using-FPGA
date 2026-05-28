`timescale 1ns / 1ps

module rgba_to_ycbcr (
    input  wire        clk,
    input  wire        rst_n,

    // AXI-Stream Input (RGBA)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,

    // AXI-Stream Output (YCbCr Packed: {A, Cr, Cb, Y})
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tuser,
    output reg         m_axis_tlast
);

    assign s_axis_tready = m_axis_tready;

    // Extract R, G, B
    wire [7:0] r = s_axis_tdata[7:0];
    wire [7:0] g = s_axis_tdata[15:8];
    wire [7:0] b = s_axis_tdata[23:16];
    wire [7:0] a = s_axis_tdata[31:24];

    // ==========================================
    // STAGE 1: Multiplications (DSP Heavy)
    // ==========================================
    reg signed [17:0] y_mult_r, y_mult_g, y_mult_b;
    reg signed [17:0] cb_mult_r, cb_mult_g, cb_mult_b;
    reg signed [17:0] cr_mult_r, cr_mult_g, cr_mult_b;
    reg [7:0] a_pipe;
    reg valid_pipe, user_pipe, last_pipe;

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_pipe <= 0;
        end else if (m_axis_tready) begin
            valid_pipe <= s_axis_tvalid;
            user_pipe  <= s_axis_tuser;
            last_pipe  <= s_axis_tlast;
            a_pipe     <= a;

            // BT.601 Coefficients scaled by 256
            y_mult_r  <= 77  * r;
            y_mult_g  <= 150 * g;
            y_mult_b  <= 29  * b;
            
            cb_mult_r <= -43 * r;
            cb_mult_g <= -84 * g;
            cb_mult_b <= 127 * b;
            
            cr_mult_r <= 127 * r;
            cr_mult_g <= -106 * g;
            cr_mult_b <= -21 * b;
        end
    end

    // ==========================================
    // STAGE 2: Additions & Offset (Final YCbCr)
    // ==========================================
    wire [7:0] y_final  = (y_mult_r + y_mult_g + y_mult_b) >>> 8;
    wire [7:0] cb_final = ((cb_mult_r + cb_mult_g + cb_mult_b) >>> 8) + 128;
    wire [7:0] cr_final = ((cr_mult_r + cr_mult_g + cr_mult_b) >>> 8) + 128;

    always @(posedge clk) begin
        if (!rst_n) begin
            m_axis_tvalid <= 0;
            m_axis_tdata  <= 0;
        end else if (m_axis_tready) begin
            m_axis_tvalid <= valid_pipe;
            m_axis_tuser  <= user_pipe;
            m_axis_tlast  <= last_pipe;
            m_axis_tdata  <= {a_pipe, cr_final, cb_final, y_final};
        end
    end

endmodule