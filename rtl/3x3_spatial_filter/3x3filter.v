module noise_filter #(
    parameter IMG_WIDTH = 640
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream Slave
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,
    
    // AXI-Stream Master
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tuser,
    output wire        m_axis_tlast
);

    assign s_axis_tready = m_axis_tready;

    // 1. Line Buffers (Vivado will infer Block RAM for this)
    reg [7:0] line_buf_0 [0:IMG_WIDTH-1];
    reg [7:0] line_buf_1 [0:IMG_WIDTH-1];
    reg [10:0] col_ptr;

    // 2. 3x3 Window Registers
    reg [7:0] w00, w01, w02; // Top Row
    reg [7:0] w10, w11, w12; // Middle Row
    reg [7:0] w20, w21, w22; // Bottom Row

    // 3. Pipeline Registers for Math
    reg [9:0]  sum_row0, sum_row1, sum_row2;
    reg [11:0] total_sum;
    reg [7:0]  final_pixel;

    // 4. Control Signal Shift Registers (to match data latency)
    // Delay = 4 cycles (Window Update -> Row Sum -> Total Sum -> Final Pixel)
    reg [3:0] valid_shift;
    reg [3:0] last_shift;
    reg [3:0] user_shift;

    wire [7:0] pixel_in = s_axis_tdata[7:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            col_ptr <= 11'd0;
            valid_shift <= 4'd0;
            last_shift  <= 4'd0;
            user_shift  <= 4'd0;
        end else if (m_axis_tready) begin
            
            // ==========================================
            // STAGE 1: Line Buffers & Window Shift
            // ==========================================
            if (s_axis_tvalid) begin
                // Read from memory for the top and middle rows
                w00 <= line_buf_1[col_ptr];
                w10 <= line_buf_0[col_ptr];
                w20 <= pixel_in; // Bottom row comes straight from input
                
                // Shift the window right
                w01 <= w00; w02 <= w01;
                w11 <= w10; w12 <= w11;
                w21 <= w20; w22 <= w21;

                // Write current pixels into memory for the next lines
                line_buf_0[col_ptr] <= pixel_in;
                line_buf_1[col_ptr] <= line_buf_0[col_ptr];

                // Advance Column Pointer
                if (s_axis_tlast)
                    col_ptr <= 11'd0;
                else
                    col_ptr <= col_ptr + 11'd1;
            end

            // ==========================================
            // STAGE 2: Sum the Rows
            // ==========================================
            sum_row0 <= w00 + w01 + w02;
            sum_row1 <= w10 + w11 + w12;
            sum_row2 <= w20 + w21 + w22;

            // ==========================================
            // STAGE 3: Total Sum
            // ==========================================
            total_sum <= sum_row0 + sum_row1 + sum_row2;

            // ==========================================
            // STAGE 4: Multiply and Shift (Divide by 9)
            // ==========================================
            // Multiply by 28 (which is 256/9) and take the upper 8 bits
            final_pixel <= (total_sum * 20'd28) >> 8;

            // ==========================================
            // STAGE 5: Sync Control Signals
            // ==========================================
            valid_shift <= {valid_shift[2:0], s_axis_tvalid};
            last_shift  <= {last_shift[2:0],  s_axis_tlast};
            user_shift  <= {user_shift[2:0],  s_axis_tuser};
        end
    end

    // Assign final outputs
    assign m_axis_tdata  = {8'hFF, final_pixel, final_pixel, final_pixel};
    assign m_axis_tvalid = valid_shift[3];
    assign m_axis_tlast  = last_shift[3];
    assign m_axis_tuser  = user_shift[3];

endmodule