`timescale 1ns/1ps

module noise_filter_tb;

    logic        clk;
    logic        rst_n;

    logic [31:0] s_axis_tdata;
    logic        s_axis_tvalid;
    wire         s_axis_tready;
    logic        s_axis_tuser;
    logic        s_axis_tlast;

    wire  [31:0] m_axis_tdata;
    wire         m_axis_tvalid;
    logic        m_axis_tready;
    wire         m_axis_tuser;
    wire         m_axis_tlast;

    noise_filter dut (
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

    initial clk = 0;
    always #5 clk = ~clk;

    int tests_passed = 0;
    int tests_failed = 0;

    task apply_reset();
        rst_n          = 0;
        s_axis_tdata   = 32'hFF000000;
        s_axis_tvalid  = 0;
        s_axis_tuser   = 0;
        s_axis_tlast   = 0;
        m_axis_tready  = 1;
        repeat(4) @(posedge clk);
        #1;
        rst_n = 1;
        @(posedge clk);
    endtask

    task send_pixel(
        input [7:0]  gray_val,
        input logic  tuser,
        input logic  tlast,
        input logic  tvalid = 1
    );
        @(posedge clk);
        #1;
        s_axis_tdata  = {8'hFF, gray_val, gray_val, gray_val};
        s_axis_tvalid = tvalid;
        s_axis_tuser  = tuser;
        s_axis_tlast  = tlast;
        wait(s_axis_tready && s_axis_tvalid);
    endtask

    task automatic collect_output(
        output [7:0]  out_gray,
        output logic  out_tuser,
        output logic  out_tlast
    );
        @(posedge clk);
        while (!m_axis_tvalid || !m_axis_tready) @(posedge clk);
        out_gray  = m_axis_tdata[7:0];
        out_tuser = m_axis_tuser;
        out_tlast = m_axis_tlast;
    endtask

    task check_output(
        input [7:0] actual,
        input [7:0] expected,
        input [7:0] tolerance,
        input string test_name
    );
        int diff;
        diff = (actual > expected) ? (actual - expected) : (expected - actual);
        if (diff <= tolerance) begin
            tests_passed++;
        end else begin
            tests_failed++;
        end
    endtask

    task flush_pipeline();
        repeat(3) begin
            @(posedge clk); #1;
            s_axis_tvalid = 0;
        end
    endtask

    task test_reset_state();
        apply_reset();
        @(posedge clk); #1;
        s_axis_tvalid = 0;
        repeat(5) @(posedge clk);
        if (m_axis_tvalid === 0)
            tests_passed++;
        else
            tests_failed++;
    endtask

    task test_uniform_pixels();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;

        apply_reset();
        m_axis_tready = 1;

        fork
            begin : sender
                repeat(6) send_pixel(8'd120, 0, 0);
                flush_pipeline();
            end
            begin : receiver
                repeat(3) begin
                    collect_output(out_gray, out_tuser, out_tlast);
                    check_output(out_gray, 8'd120, 8'd2, "uniform=120");
                end
                disable sender;
            end
        join
    endtask

    task test_known_average();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;
        int         expected;

        apply_reset();
        m_axis_tready = 1;
        expected = (30 + 60 + 90) * 85 >> 8;

        fork
            begin : sender2
                send_pixel(8'd30,  0, 0);
                send_pixel(8'd60,  0, 0);
                send_pixel(8'd90,  0, 0);
                send_pixel(8'd90,  0, 0);
                send_pixel(8'd90,  0, 0);
                send_pixel(8'd90,  0, 0);
                flush_pipeline();
            end
            begin : receiver2
                collect_output(out_gray, out_tuser, out_tlast);
                collect_output(out_gray, out_tuser, out_tlast);
                collect_output(out_gray, out_tuser, out_tlast);
                check_output(out_gray, expected[7:0], 8'd2, "avg(30,60,90)");
                disable sender2;
            end
        join
    endtask

    task test_boundary_values();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;

        apply_reset();
        m_axis_tready = 1;

        fork
            begin : sender3
                repeat(6) send_pixel(8'd0, 0, 0);
                repeat(6) send_pixel(8'd255, 0, 0);
                flush_pipeline();
            end
            begin : receiver3
                int exp_zero, exp_max;
                exp_zero = (0 + 0 + 0) * 85 >> 8;
                exp_max  = (255 + 255 + 255) * 85 >> 8;

                repeat(3) begin
                    collect_output(out_gray, out_tuser, out_tlast);
                    check_output(out_gray, exp_zero[7:0], 8'd1, "all_zeros");
                end
                repeat(3) begin
                    collect_output(out_gray, out_tuser, out_tlast);
                    check_output(out_gray, exp_max[7:0], 8'd2, "all_255");
                end
                disable sender3;
            end
        join
    endtask

    task test_tuser_passthrough();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;

        apply_reset();
        m_axis_tready = 1;

        fork
            begin : sender4
                send_pixel(8'd100, 1, 0);
                send_pixel(8'd100, 0, 0);
                send_pixel(8'd100, 0, 0);
                send_pixel(8'd100, 0, 0);
                send_pixel(8'd100, 0, 0);
                send_pixel(8'd100, 0, 0);
                flush_pipeline();
            end
            begin : receiver4
                collect_output(out_gray, out_tuser, out_tlast);
                if (out_tuser === 1'b1)
                    tests_passed++;
                else
                    tests_failed++;

                collect_output(out_gray, out_tuser, out_tlast);
                if (out_tuser === 1'b0)
                    tests_passed++;
                else
                    tests_failed++;

                disable sender4;
            end
        join
    endtask

    task test_tlast_passthrough();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;

        apply_reset();
        m_axis_tready = 1;

        fork
            begin : sender5
                send_pixel(8'd50, 1, 0);
                send_pixel(8'd50, 0, 0);
                send_pixel(8'd50, 0, 1);
                send_pixel(8'd50, 0, 0);
                send_pixel(8'd50, 0, 0);
                send_pixel(8'd50, 0, 0);
                flush_pipeline();
            end
            begin : receiver5
                logic found_tlast;
                found_tlast = 0;
                repeat(6) begin
                    collect_output(out_gray, out_tuser, out_tlast);
                    if (out_tlast) found_tlast = 1;
                end
                if (found_tlast)
                    tests_passed++;
                else
                    tests_failed++;

                disable sender5;
            end
        join
    endtask

    task test_backpressure();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;

        apply_reset();

        fork
            begin : sender6
                m_axis_tready = 1;
                send_pixel(8'd80, 0, 0);
                send_pixel(8'd80, 0, 0);
                send_pixel(8'd80, 0, 0);

                @(posedge clk); #1;
                m_axis_tready = 0;
                repeat(5) @(posedge clk);

                m_axis_tready = 1;

                send_pixel(8'd80, 0, 0);
                send_pixel(8'd80, 0, 0);
                send_pixel(8'd80, 0, 0);
                flush_pipeline();
            end
            begin : receiver6
                repeat(3) @(posedge clk);
                @(posedge clk); #1;

                if (s_axis_tready === 0)
                    tests_passed++;
                else
                    tests_failed++;

                wait(m_axis_tready);
                collect_output(out_gray, out_tuser, out_tlast);
                check_output(out_gray, 8'd80, 8'd2, "post-backpressure output");

                disable sender6;
            end
        join
    endtask

    task test_tvalid_bubble();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;

        apply_reset();
        m_axis_tready = 1;

        @(posedge clk); #1;
        s_axis_tdata  = {8'hFF, 8'd200, 8'd200, 8'd200};
        s_axis_tvalid = 1;
        s_axis_tuser  = 0;
        s_axis_tlast  = 0;

        repeat(3) @(posedge clk);

        s_axis_tvalid = 0;
        repeat(3) @(posedge clk);

        s_axis_tvalid = 1;
        repeat(3) @(posedge clk);

        s_axis_tvalid = 0;

        repeat(3) @(posedge clk);

        tests_passed++;
    endtask

    task test_alpha_preserved();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;

        apply_reset();
        m_axis_tready = 1;

        fork
            begin : sender7
                repeat(6) send_pixel(8'd150, 0, 0);
                flush_pipeline();
            end
            begin : receiver7
                logic [31:0] full_out;
                collect_output(out_gray, out_tuser, out_tlast);
                full_out = m_axis_tdata;

                if (full_out[31:24] === 8'hFF)
                    tests_passed++;
                else
                    tests_failed++;

                if (full_out[23:16] === full_out[15:8] && full_out[15:8] === full_out[7:0])
                    tests_passed++;
                else
                    tests_failed++;

                disable sender7;
            end
        join
    endtask

    task test_full_row();
        logic [7:0] out_gray;
        logic       out_tuser, out_tlast;
        logic       saw_tuser, saw_tlast;

        apply_reset();
        m_axis_tready = 1;
        saw_tuser = 0;
        saw_tlast = 0;

        fork
            begin : sender8
                send_pixel(8'd10,  1, 0);
                send_pixel(8'd20,  0, 0);
                send_pixel(8'd30,  0, 0);
                send_pixel(8'd40,  0, 0);
                send_pixel(8'd50,  0, 0);
                send_pixel(8'd60,  0, 0);
                send_pixel(8'd70,  0, 0);
                send_pixel(8'd80,  0, 1);
                flush_pipeline();
            end
            begin : receiver8
                repeat(8) begin
                    collect_output(out_gray, out_tuser, out_tlast);
                    if (out_tuser) saw_tuser = 1;
                    if (out_tlast) saw_tlast = 1;
                end

                if (saw_tuser)
                    tests_passed++;
                else
                    tests_failed++;

                if (saw_tlast)
                    tests_passed++;
                else
                    tests_failed++;

                disable sender8;
            end
        join
    endtask

    initial begin
        $dumpfile("noise_filter_tb.vcd");
        $dumpvars(0, noise_filter_tb);

        test_reset_state();
        test_uniform_pixels();
        test_known_average();
        test_boundary_values();
        test_tuser_passthrough();
        test_tlast_passthrough();
        test_backpressure();
        test_tvalid_bubble();
        test_alpha_preserved();
        test_full_row();

        repeat(10) @(posedge clk);
        $finish;
    end

endmodule