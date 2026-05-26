`timescale 1ns/1ps

module sobel_edge_tb;

    localparam int IMG_WIDTH = 8;

    logic        clk;
    logic        rst_n;

    logic [31:0] s_axis_tdata;
    logic        s_axis_tvalid;
    wire         s_axis_tready;
    logic        s_axis_tuser;
    logic        s_axis_tlast;

    wire [31:0]  m_axis_tdata;
    wire         m_axis_tvalid;
    logic        m_axis_tready;
    wire         m_axis_tuser;
    wire         m_axis_tlast;

    logic [7:0] flat  [0:7] = '{8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128, 8'd128};
    logic [7:0] row0  [0:7] = '{8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0};
    logic [7:0] row1  [0:7] = '{8'd255, 8'd255, 8'd255, 8'd255, 8'd255, 8'd255, 8'd255, 8'd255};
    logic [7:0] row2  [0:7] = '{8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0};
    logic [7:0] zeros [0:7] = '{8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0};
    logic [7:0] maxval[0:7] = '{8'd255, 8'd255, 8'd255, 8'd255, 8'd255, 8'd255, 8'd255, 8'd255};

    logic [7:0] vert0 [0:7] = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd255, 8'd255, 8'd255, 8'd255};
    logic [7:0] vert1 [0:7] = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd255, 8'd255, 8'd255, 8'd255};
    logic [7:0] vert2 [0:7] = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd255, 8'd255, 8'd255, 8'd255};

    sobel_edge #(
        .IMG_WIDTH(IMG_WIDTH)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .s_axis_tuser   (s_axis_tuser),
        .s_axis_tlast   (s_axis_tlast),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tuser   (m_axis_tuser),
        .m_axis_tlast   (m_axis_tlast)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic apply_reset();
        rst_n         = 1'b0;
        s_axis_tdata  = 32'd0;
        s_axis_tvalid = 1'b0;
        s_axis_tuser  = 1'b0;
        s_axis_tlast  = 1'b0;
        m_axis_tready = 1'b1;
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(3) @(posedge clk);
    endtask

    task automatic send_pixel(
        input logic [7:0] val,
        input logic       tuser,
        input logic       tlast
    );
        while (s_axis_tready !== 1'b1) begin
            @(posedge clk);
        end

        @(posedge clk);
        #1;
        s_axis_tdata  = {8'hFF, val, val, val};
        s_axis_tvalid = 1'b1;
        s_axis_tuser  = tuser;
        s_axis_tlast  = tlast;

        @(posedge clk);
        #1;
        s_axis_tvalid = 1'b0;
        s_axis_tuser  = 1'b0;
        s_axis_tlast  = 1'b0;
    endtask

    task automatic send_row(
        input logic [7:0] pixels [0:7],
        input logic       frame_start
    );
        for (int i = 0; i < IMG_WIDTH; i++) begin
            send_pixel(
                pixels[i],
                (i == 0) ? frame_start : 1'b0,
                (i == IMG_WIDTH - 1) ? 1'b1 : 1'b0
            );
        end
    endtask

    task automatic idle_cycles(input int count);
        repeat(count) @(posedge clk);
    endtask

    task automatic valid_bubble_test();
        send_pixel(8'd100, 1'b0, 1'b0);
        idle_cycles(3);
        send_pixel(8'd100, 1'b0, 1'b0);
        idle_cycles(3);
        send_pixel(8'd100, 1'b0, 1'b1);
        idle_cycles(10);
    endtask

    task automatic backpressure_test();
        send_pixel(8'd80, 1'b0, 1'b0);
        send_pixel(8'd80, 1'b0, 1'b0);

        @(posedge clk);
        #1;
        m_axis_tready = 1'b0;

        repeat(5) @(posedge clk);

        m_axis_tready = 1'b1;

        send_pixel(8'd80, 1'b0, 1'b0);
        send_pixel(8'd80, 1'b0, 1'b1);

        idle_cycles(10);
    endtask

    task automatic reset_midstream_test();
        send_pixel(8'd200, 1'b1, 1'b0);
        send_pixel(8'd200, 1'b0, 1'b0);

        @(posedge clk);
        #1;
        rst_n = 1'b0;

        repeat(4) @(posedge clk);

        rst_n = 1'b1;

        repeat(8) @(posedge clk);
    endtask

    initial begin
        $dumpfile("sobel_edge_tb.vcd");
        $dumpvars(0, sobel_edge_tb);

        apply_reset();

        send_row(flat, 1'b1);
        send_row(flat, 1'b0);
        send_row(flat, 1'b0);
        idle_cycles(15);

        send_row(row0, 1'b1);
        send_row(row1, 1'b0);
        send_row(row2, 1'b0);
        idle_cycles(15);

        send_row(zeros, 1'b1);
        send_row(zeros, 1'b0);
        send_row(zeros, 1'b0);
        idle_cycles(15);

        send_row(maxval, 1'b1);
        send_row(maxval, 1'b0);
        send_row(maxval, 1'b0);
        idle_cycles(15);

        send_row(vert0, 1'b1);
        send_row(vert1, 1'b0);
        send_row(vert2, 1'b0);
        idle_cycles(15);

        backpressure_test();

        valid_bubble_test();

        reset_midstream_test();

        idle_cycles(20);

        $finish;
    end

endmodule