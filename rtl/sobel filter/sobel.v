module sobel_edge #(
    parameter IMG_WIDTH = 640
)(
    input  wire        clk,
    input  wire        rst_n,

    // AXI-Stream Slave (Input from Contrast)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,

    // AXI-Stream Master (Output to Zynq/VDMA)
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tuser,
    output wire        m_axis_tlast
);

    assign s_axis_tready = m_axis_tready;

    // Line Buffers
    reg [7:0] line_buf_0 [0:IMG_WIDTH-1];
    reg [7:0] line_buf_1 [0:IMG_WIDTH-1];
    reg [10:0] col_ptr;

    // 3x3 Window
    reg [7:0] w00, w01, w02;
    reg [7:0] w10, w11, w12;
    reg [7:0] w20, w21, w22;

    // Pipeline Registers for Math (To fix Timing/WNS)
    reg [10:0] gx_pos, gx_neg;
    reg [10:0] gy_pos, gy_neg;
    reg [10:0] gx_abs, gy_abs;
    reg [11:0] g_sum;
    reg [7:0]  final_pixel;

    // Control Signal Shift Registers (Delay = 5 cycles)
    reg [4:0] valid_shift, last_shift, user_shift;
///
reg [23:0] color_pipe [0:4];
    wire [7:0] pixel_in = s_axis_tdata[7:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            col_ptr <= 11'd0;
            valid_shift <= 5'd0;
            last_shift  <= 5'd0;
            user_shift  <= 5'd0;
        end else if (m_axis_tready) begin

            // ==========================================
            // STAGE 1: Update Window (Cycle 1)
            // ==========================================
            if (s_axis_tvalid) begin
                w00 <= line_buf_1[col_ptr]; w10 <= line_buf_0[col_ptr]; w20 <= pixel_in;
                w01 <= w00; w02 <= w01;
                w11 <= w10; w12 <= w11;
                w21 <= w20; w22 <= w21;

                line_buf_0[col_ptr] <= pixel_in;
                line_buf_1[col_ptr] <= line_buf_0[col_ptr];

                col_ptr <= (s_axis_tlast) ? 11'd0 : col_ptr + 11'd1;
            end

            // ==========================================
            // STAGE 2: Convolution Sums (Cycle 2)
            // Multiply by 2 is done by shifting left by 1 (<< 1)
            // ==========================================
            gx_pos <= w02 + (w12 << 1) + w22;
            gx_neg <= w00 + (w10 << 1) + w20;

            gy_pos <= w00 + (w01 << 1) + w02;
            gy_neg <= w20 + (w21 << 1) + w22;

            // ==========================================
            // STAGE 3: Absolute Differences (Cycle 3)
            // ==========================================
            gx_abs <= (gx_pos > gx_neg) ? (gx_pos - gx_neg) : (gx_neg - gx_pos);
            gy_abs <= (gy_pos > gy_neg) ? (gy_pos - gy_neg) : (gy_neg - gy_pos);

            // ==========================================
            // STAGE 4: Total Gradient (Cycle 4)
            // ==========================================
            g_sum <= gx_abs + gy_abs;

            // ==========================================
            // STAGE 5: Clamp to 255 (Cycle 5)
            // ==========================================
            final_pixel <= (g_sum > 12'd255) ? 8'd255 : g_sum[7:0];

            // Sync Control Signals
            valid_shift <= {valid_shift[3:0], s_axis_tvalid};
            last_shift  <= {last_shift[3:0],  s_axis_tlast};
            user_shift  <= {user_shift[3:0],  s_axis_tuser};
            // ADD THESE LINES:
            color_pipe[0] <= s_axis_tdata[31:8];
            color_pipe[1] <= color_pipe[0];
            color_pipe[2] <= color_pipe[1];
            color_pipe[3] <= color_pipe[2];
            color_pipe[4] <= color_pipe[3];
        end
    end

    //assign m_axis_tdata  = {8'hFF, final_pixel, final_pixel, final_pixel};
    // OLD: {8'hFF, final_pixel, final_pixel, final_pixel}
    assign m_axis_tdata = {color_pipe[4], final_pixel};
    assign m_axis_tvalid = valid_shift[4];
    assign m_axis_tlast  = last_shift[4];
    assign m_axis_tuser  = user_shift[4];

endmodule
