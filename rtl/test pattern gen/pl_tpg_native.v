module pl_tpg_native (
    input  wire        clk,           // 148.5 MHz
    input  wire        rst_n,         // active low reset
    output reg  [23:0] vid_data,      // RGB24
    output reg         vid_hsync,     // horizontal sync
    output reg         vid_vsync,     // vertical sync
    output reg         vid_active_video  // data enable
);

    // 1080p timing
    localparam H_ACTIVE = 1920;
    localparam H_TOTAL  = 2200;
    localparam H_SYNC_START = 2008;
    localparam H_SYNC_END   = 2052;
    localparam V_ACTIVE = 1080;
    localparam V_TOTAL  = 1125;
    localparam V_SYNC_START = 1084;
    localparam V_SYNC_END   = 1089;

    reg [11:0] h_cnt = 0;
    reg [11:0] v_cnt = 0;

    always @(posedge clk) begin
        if (!rst_n) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1) v_cnt <= 0;
                else                      v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    // Color bars
    wire [2:0] bar = h_cnt[11:9];
    reg [23:0] pixel;
    always @(*) begin
        case (bar)
            3'd0: pixel = 24'hFF0000;
            3'd1: pixel = 24'h00FF00;
            3'd2: pixel = 24'h0000FF;
            3'd3: pixel = 24'hFFFF00;
            3'd4: pixel = 24'h00FFFF;
            3'd5: pixel = 24'hFF00FF;
            3'd6: pixel = 24'hFFFFFF;
            3'd7: pixel = 24'h000000;
        endcase
    end

    // Native video outputs
    always @(posedge clk) begin
        if (!rst_n) begin
            vid_data <= 0;
            vid_hsync <= 0;
            vid_vsync <= 0;
            vid_active_video <= 0;
        end else begin
            vid_active_video <= (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
            vid_hsync <= (h_cnt >= H_SYNC_START) && (h_cnt < H_SYNC_END);
            vid_vsync <= (v_cnt >= V_SYNC_START) && (v_cnt < V_SYNC_END);
            vid_data <= pixel;
        end
    end

endmodule
