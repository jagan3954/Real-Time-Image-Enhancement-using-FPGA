module rgb_to_gray (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [7:0]  pixel_r,
    input  wire [7:0]  pixel_g,
    input  wire [7:0]  pixel_b,
    input  wire        pixel_valid,
    input  wire [9:0]  pixel_x,
    input  wire [8:0]  pixel_y,

    output reg  [7:0]  gray_out,
    output reg         gray_valid,
    output reg  [9:0]  gray_x,
    output reg  [8:0]  gray_y
);

parameter COEFF_R = 10'd306;   // 0.299 × 1024
parameter COEFF_G = 10'd601;   // 0.587 × 1024
parameter COEFF_B = 10'd117;   // 0.114 × 1024

// ─── Stage 1: Multiply ────────────────────────────────────────
reg [17:0] mult_r, mult_g, mult_b;
reg        valid_s1;
reg [9:0]  x_s1;
reg [8:0]  y_s1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mult_r   <= 18'd0;
        mult_g   <= 18'd0;
        mult_b   <= 18'd0;
        valid_s1 <= 1'b0;
        x_s1     <= 10'd0;
        y_s1     <= 9'd0;
    end else begin
        mult_r   <= pixel_r * COEFF_R;
        mult_g   <= pixel_g * COEFF_G;
        mult_b   <= pixel_b * COEFF_B;
        valid_s1 <= pixel_valid;
        x_s1     <= pixel_x;
        y_s1     <= pixel_y;
    end
end

// ─── Stage 2: Add ─────────────────────────────────────────────
reg [19:0] sum;
reg        valid_s2;
reg [9:0]  x_s2;
reg [8:0]  y_s2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum      <= 20'd0;
        valid_s2 <= 1'b0;
        x_s2     <= 10'd0;
        y_s2     <= 9'd0;
    end else begin
        sum      <= mult_r + mult_g + mult_b;
        valid_s2 <= valid_s1;
        x_s2     <= x_s1;
        y_s2     <= y_s1;
    end
end

// ─── Stage 3: Shift ───────────────────────────────────────────
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray_out   <= 8'd0;
        gray_valid <= 1'b0;
        gray_x     <= 10'd0;
        gray_y     <= 9'd0;
    end else begin
        gray_out   <= sum[17:10];
        gray_valid <= valid_s2;
        gray_x     <= x_s2;
        gray_y     <= y_s2;
    end
end

endmodule