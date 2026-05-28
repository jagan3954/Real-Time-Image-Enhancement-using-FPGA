`timescale 1ns / 1ps

module ycbcr_to_rgba (
    input  wire        clk,
    input  wire        rst_n,

    // AXI-Stream Input (YCbCr Packed: {A, Cr, Cb, Y})
    input  wire [31:0] s_axis_tdata, 
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,

    // AXI-Stream Output (RGBA)
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tuser,
    output reg         m_axis_tlast
);

    assign s_axis_tready = m_axis_tready;

    // Extract Y, Cb, Cr
    wire [7:0] y  = s_axis_tdata[7:0];
    wire [7:0] cb = s_axis_tdata[15:8];
    wire [7:0] cr = s_axis_tdata[23:16];
    wire [7:0] a  = s_axis_tdata[31:24];

    // Convert to signed and remove the 128 offset from Cb/Cr
    wire signed [16:0] y_s  = {1'b0, y};
    wire signed [16:0] cb_s = {1'b0, cb} - 128;
    wire signed [16:0] cr_s = {1'b0, cr} - 128;

    // ==========================================
    // PIPELINE STAGE 1: Multiplication
    // ==========================================
    reg signed [31:0] r_mult, g_mult_cb, g_mult_cr, b_mult;
    reg signed [16:0] y_pipe;
    reg [7:0] a_pipe;
    reg valid_pipe, user_pipe, last_pipe;

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_pipe <= 1'b0;
            user_pipe  <= 1'b0;
            last_pipe  <= 1'b0;
            a_pipe     <= 8'd0;
            y_pipe     <= 17'd0;
            r_mult     <= 32'd0;
            g_mult_cb  <= 32'd0;
            g_mult_cr  <= 32'd0;
            b_mult     <= 32'd0;
        end else if (m_axis_tready) begin
            // Pass through control signals
            valid_pipe <= s_axis_tvalid;
            user_pipe  <= s_axis_tuser;
            last_pipe  <= s_axis_tlast;
            a_pipe     <= a;
            y_pipe     <= y_s;
            
            // Do the heavy multiplications in cycle 1
            // This isolates the DSP blocks from the adders
            r_mult     <= 359 * cr_s;
            g_mult_cb  <=  88 * cb_s;
            g_mult_cr  <= 183 * cr_s;
            b_mult     <= 454 * cb_s;
        end
    end

    // ==========================================
    // PIPELINE STAGE 2: Addition & Clamping
    // ==========================================
    wire signed [16:0] r_tmp = y_pipe + (r_mult >>> 8);
    wire signed [16:0] g_tmp = y_pipe - ((g_mult_cb + g_mult_cr) >>> 8);
    wire signed [16:0] b_tmp = y_pipe + (b_mult >>> 8);

    // Clamping logic: Colors cannot be negative or over 255
    wire [7:0] r_out = (r_tmp < 0) ? 8'd0 : (r_tmp > 255) ? 8'd255 : r_tmp[7:0];
    wire [7:0] g_out = (g_tmp < 0) ? 8'd0 : (g_tmp > 255) ? 8'd255 : g_tmp[7:0];
    wire [7:0] b_out = (b_tmp < 0) ? 8'd0 : (b_tmp > 255) ? 8'd255 : b_tmp[7:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tuser  <= 1'b0;
            m_axis_tlast  <= 1'b0;
            m_axis_tdata  <= 32'd0;
        end else if (m_axis_tready) begin
            m_axis_tvalid <= valid_pipe;
            m_axis_tuser  <= user_pipe;
            m_axis_tlast  <= last_pipe;
            // Repack to RGBA
            m_axis_tdata  <= {a_pipe, b_out, g_out, r_out};
        end
    end

endmodule