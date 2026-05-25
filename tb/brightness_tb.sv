`timescale 1ns / 1ps

module tb_brightness_ctrl();

    // Signals
    logic [7:0]  brightness_offset;
    logic [31:0] s_axis_tdata, m_axis_tdata;
    logic        s_axis_tvalid, s_axis_tready, s_axis_tuser, s_axis_tlast;
    logic        m_axis_tvalid, m_axis_tready, m_axis_tuser, m_axis_tlast;
    
    logic clk = 0;
    always #5 clk = ~clk; // 100MHz clock simulation

    // Instantiate Module
    brightness_ctrl dut (.*);

    // Task to send a pixel
    task send_pixel(input [7:0] r, input [7:0] g, input [7:0] b, input [7:0] a);
        s_axis_tdata  = {a, b, g, r};
        s_axis_tvalid = 1;
        wait(s_axis_tready);
        @(posedge clk);
        s_axis_tvalid = 0;
    endtask

    initial begin
        // Initialize
        brightness_offset = 8'd50; // Add 50 brightness
        s_axis_tvalid = 0;
        m_axis_tready = 1;
        s_axis_tuser  = 0;
        s_axis_tlast  = 0;

        $display("--- Starting Brightness Control Sim (Offset: %d) ---", brightness_offset);
        repeat(5) @(posedge clk);

        // Test Case 1: Normal Pixel (No Overflow)
        // Input: R=100, G=100, B=100 -> Expected Output: 150, 150, 150
        $display("Test 1: Normal Addition");
        send_pixel(8'd100, 8'd100, 8'd100, 8'hFF);
        #1; // Wait for logic propagation
        $display("Out: R=%d, G=%d, B=%d", m_axis_tdata[7:0], m_axis_tdata[15:8], m_axis_tdata[23:16]);

        // Test Case 2: Overflow (Clamping to 255)
        // Input: R=220, G=220, B=220 -> (220+50 = 270) -> Expected Output: 255, 255, 255
        $display("Test 2: Overflow Clamping");
        send_pixel(8'd220, 8'd220, 8'd220, 8'hFF);
        #1;
        $display("Out: R=%d, G=%d, B=%d", m_axis_tdata[7:0], m_axis_tdata[15:8], m_axis_tdata[23:16]);

        // Test Case 3: Changing Offset on the fly
        brightness_offset = 8'd10;
        $display("Test 3: Small Offset (Offset: 10)");
        send_pixel(8'd200, 8'd200, 8'd200, 8'hFF);
        #1;
        $display("Out: R=%d, G=%d, B=%d", m_axis_tdata[7:0], m_axis_tdata[15:8], m_axis_tdata[23:16]);

        $display("--- Simulation Finished ---");
        $finish;
    end
endmodule