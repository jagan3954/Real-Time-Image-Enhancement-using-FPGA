module brightness_controller (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [7:0]  gray_in,
    input  wire        gray_valid,
    input  wire [9:0]  gray_x,
    input  wire [8:0]  gray_y,

    input  wire [7:0]  bright_level,
    input  wire        bright_dir,

    output reg  [7:0]  bright_out,
    output reg         bright_valid,
    output reg  [9:0]  bright_x,
    output reg  [8:0]  bright_y
);

reg [8:0] result;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bright_out   <= 8'd0;
        bright_valid <= 1'b0;
        bright_x     <= 10'd0;
        bright_y     <= 9'd0;
        result       <= 9'd0;
    end else begin
        bright_valid <= gray_valid;
        bright_x     <= gray_x;
        bright_y     <= gray_y;

        if (gray_valid) begin
            if (bright_dir == 1'b1) begin
                result = {1'b0, gray_in} + {1'b0, bright_level};
                if (result > 9'd255)
                    bright_out <= 8'd255;
                else
                    bright_out <= result[7:0];
            end else begin
                if (bright_level >= gray_in)
                    bright_out <= 8'd0;
                else
                    bright_out <= gray_in - bright_level;
            end
        end
    end
end

endmodule