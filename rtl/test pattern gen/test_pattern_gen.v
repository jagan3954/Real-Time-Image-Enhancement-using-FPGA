module test_pattern_gen (
    input  wire        pclk,
    input  wire        rst_n,
    output reg         hSync,
    output reg         vSync,
    output reg         de,
    output reg  [23:0] rgb
);

// 1080p 60Hz timing
parameter H_ACTIVE = 1920;
parameter H_FP     = 88;
parameter H_SYNC   = 44;
parameter H_BP     = 148;
parameter H_TOTAL  = 2200;

parameter V_ACTIVE = 1080;
parameter V_FP     = 4;
parameter V_SYNC   = 5;
parameter V_BP     = 36;
parameter V_TOTAL  = 1125;

reg [11:0] h_cnt;
reg [11:0] v_cnt;

// Horizontal and vertical counters
always @(posedge pclk or negedge rst_n) begin
    if (!rst_n) begin
        h_cnt <= 0;
        v_cnt <= 0;
    end else begin
        if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 0;
            if (v_cnt == V_TOTAL - 1)
                v_cnt <= 0;
            else
                v_cnt <= v_cnt + 1;
        end else begin
            h_cnt <= h_cnt + 1;
        end
    end
end

// Active area
wire h_active = (h_cnt < H_ACTIVE);
wire v_active = (v_cnt < V_ACTIVE);

// Output signals
always @(posedge pclk or negedge rst_n) begin
    if (!rst_n) begin
        de    <= 0;
        hSync <= 0;
        vSync <= 0;
        rgb   <= 0;
    end else begin
        de    <= h_active && v_active;
        hSync <= (h_cnt >= H_ACTIVE + H_FP) && 
                 (h_cnt < H_ACTIVE + H_FP + H_SYNC);
        vSync <= (v_cnt >= V_ACTIVE + V_FP) && 
                 (v_cnt < V_ACTIVE + V_FP + V_SYNC);

        if (h_active && v_active) begin
            // 8 color bars across 1920 pixels = 240 pixels each
            if      (h_cnt < 240)  rgb <= 24'hFFFFFF; // white
            else if (h_cnt < 480)  rgb <= 24'hFFFF00; // yellow
            else if (h_cnt < 720)  rgb <= 24'h00FFFF; // cyan
            else if (h_cnt < 960)  rgb <= 24'h00FF00; // green
            else if (h_cnt < 1200) rgb <= 24'hFF00FF; // magenta
            else if (h_cnt < 1440) rgb <= 24'hFF0000; // red
            else if (h_cnt < 1680) rgb <= 24'h0000FF; // blue
            else                   rgb <= 24'h000000; // black
        end else begin
            rgb <= 24'h000000;
        end
    end
end

endmodule