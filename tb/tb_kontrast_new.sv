`timescale 1ns / 1ps

module tb_contrast_enhance;

    // ------------------------------------------------------------------ //
    //  DUT Signals
    // ------------------------------------------------------------------ //
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

    // ------------------------------------------------------------------ //
    //  DUT Instantiation
    // ------------------------------------------------------------------ //
    contrast_enhance #(
        .GAIN(8'd96),
        .BIAS(-9'sd32)
    ) dut (
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .s_axis_tuser  (s_axis_tuser),
        .s_axis_tlast  (s_axis_tlast),
        .m_axis_tdata  (m_axis_tdata),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready),
        .m_axis_tuser  (m_axis_tuser),
        .m_axis_tlast  (m_axis_tlast)
    );

    // ------------------------------------------------------------------ //
    //  Helper: Expected value (mirrors DUT math exactly)
    // ------------------------------------------------------------------ //
    function automatic [7:0] expected_ch (input [7:0] ch);
        logic signed [16:0] scaled, biased;
        scaled = ($signed({1'b0, ch}) * $signed({1'b0, 8'd96})) >>> 6;
        biased = scaled + (-9'sd32);
        if      (biased[16])        return 8'd0;
        else if (biased > 17'sd255) return 8'd255;
        else                        return biased[7:0];
    endfunction

    // ------------------------------------------------------------------ //
    //  Helper: Drive one pixel and assert outputs
    // ------------------------------------------------------------------ //
    task automatic send_pixel (
        input [7:0]  r, g, b, a,
        input        tuser, tlast
    );
        s_axis_tdata  = {a, b, g, r};
        s_axis_tvalid = 1'b1;
        s_axis_tuser  = tuser;
        s_axis_tlast  = tlast;
        m_axis_tready = 1'b1;
        #1;

        assert (m_axis_tdata[7:0]   === expected_ch(r)) else $error("R mismatch");
        assert (m_axis_tdata[15:8]  === expected_ch(g)) else $error("G mismatch");
        assert (m_axis_tdata[23:16] === expected_ch(b)) else $error("B mismatch");
        assert (m_axis_tdata[31:24] === a)              else $error("Alpha changed");
        assert (m_axis_tvalid       === s_axis_tvalid)  else $error("tvalid passthrough failed");
        assert (s_axis_tready       === m_axis_tready)  else $error("tready passthrough failed");
        assert (m_axis_tuser        === tuser)           else $error("tuser passthrough failed");
        assert (m_axis_tlast        === tlast)           else $error("tlast passthrough failed");
        #9;
    endtask

    // ------------------------------------------------------------------ //
    //  Helper: Back-pressure
    // ------------------------------------------------------------------ //
    task automatic test_backpressure;
        s_axis_tdata  = 32'hFF_80_80_80;
        s_axis_tvalid = 1'b1;
        s_axis_tuser  = 1'b0;
        s_axis_tlast  = 1'b0;
        m_axis_tready = 1'b0;
        #1;

        assert (s_axis_tready === 1'b0) else $error("tready should be 0 when m_axis_tready=0");

        m_axis_tready = 1'b1;
        #9;
    endtask

    // ------------------------------------------------------------------ //
    //  Helper: Bubble (tvalid de-asserted)
    // ------------------------------------------------------------------ //
    task automatic test_bubble;
        s_axis_tvalid = 1'b0;
        m_axis_tready = 1'b1;
        #1;

        assert (m_axis_tvalid === 1'b0) else $error("m_axis_tvalid should be 0 when s_axis_tvalid=0");
        #9;
    endtask

    // ------------------------------------------------------------------ //
    //  Main Test Sequence
    // ------------------------------------------------------------------ //
    initial begin
        s_axis_tdata  = '0;
        s_axis_tvalid = '0;
        s_axis_tuser  = '0;
        s_axis_tlast  = '0;
        m_axis_tready = '0;
        #10;

        // Boundary / Corner Cases
        send_pixel(8'd0,   8'd0,   8'd0,   8'hFF, 0, 0);
        send_pixel(8'd255, 8'd255, 8'd255, 8'hFF, 0, 0);
        send_pixel(8'd128, 8'd128, 8'd128, 8'hFF, 0, 0);

        // Clamp Tests
        send_pixel(8'd220, 8'd220, 8'd220, 8'hFF, 0, 0);
        send_pixel(8'd10,  8'd10,  8'd10,  8'hFF, 0, 0);

        // Primary Colors
        send_pixel(8'd200, 8'd0,   8'd0,   8'hFF, 0, 0);
        send_pixel(8'd0,   8'd200, 8'd0,   8'hFF, 0, 0);
        send_pixel(8'd0,   8'd0,   8'd200, 8'hFF, 0, 0);

        // Alpha Preservation
        send_pixel(8'd128, 8'd64,  8'd32,  8'h00, 0, 0);
        send_pixel(8'd128, 8'd64,  8'd32,  8'h7F, 0, 0);
        send_pixel(8'd128, 8'd64,  8'd32,  8'hAB, 0, 0);

        // AXI-Stream Framing Signals
        send_pixel(8'd100, 8'd150, 8'd200, 8'hFF, 1, 0);
        send_pixel(8'd100, 8'd150, 8'd200, 8'hFF, 0, 1);
        send_pixel(8'd100, 8'd150, 8'd200, 8'hFF, 1, 1);

        // Handshake Tests
        test_backpressure();
        test_bubble();

        // Sweep: Every 16th value
        for (int i = 0; i <= 255; i += 16)
            send_pixel(i[7:0], i[7:0], i[7:0], 8'hFF, 0, 0);

        $finish;
    end

endmodule