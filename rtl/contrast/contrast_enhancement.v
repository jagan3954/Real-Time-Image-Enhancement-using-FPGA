`timescale 1ns/1ps

module contrast_enhancement (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [7:0]  pixel_in,
    input  wire        pixel_valid,
    input  wire [9:0]  pixel_x,
    input  wire [8:0]  pixel_y,

    input  wire [7:0]  contrast_level,

    output reg  [7:0]  contrast_out,
    output reg         contrast_valid,
    output reg  [9:0]  contrast_x,
    output reg  [8:0]  contrast_y
);

wire [8:0] add_result;

assign add_result = {1'b0, pixel_in} + {1'b0, contrast_level};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        contrast_out   <= 8'd0;
        contrast_valid <= 1'b0;
        contrast_x     <= 10'd0;
        contrast_y     <= 9'd0;
    end
    else begin
        contrast_valid <= pixel_valid;
        contrast_x     <= pixel_x;
        contrast_y     <= pixel_y;

        if (pixel_valid) begin
            if (pixel_in > 8'd128) begin
                if (add_result > 9'd255)
                    contrast_out <= 8'd255;
                else
                    contrast_out <= add_result[7:0];
            end
            else if (pixel_in < 8'd128) begin
                if (contrast_level >= pixel_in)
                    contrast_out <= 8'd0;
                else
                    contrast_out <= pixel_in - contrast_level;
            end
            else begin
                contrast_out <= pixel_in;
            end
        end
    end
end

endmodule