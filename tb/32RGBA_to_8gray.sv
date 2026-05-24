`timescale 1ns / 1ps

module tb_rgba_to_gray();

    // 1. Signals
    logic [31:0] s_axis_tdata;
    logic        s_axis_tvalid;
    logic        s_axis_tready;
    logic        s_axis_tuser;
    logic        s_axis_tlast;

    logic [31:0] m_axis_tdata;
    logic        m_axis_tvalid;
    logic        m_axis_tready;
    logic        m_axis_tuser;
    logic        m_axis_tlast;

    // Clock for timing the stimulus
    logic clk = 0;
    always #5 clk = ~clk; // 100MHz

    // 2. Instantiate the Design Under Test (DUT)
    rgba_to_gray dut (.*); // Uses SV wildcard to connect matching names

    // 3. Task to send a pixel (Simulates VDMA behavior)
    task send_pixel(input [7:0] r, input [7:0] g, input [7:0] b, input [7:0] a, input last, input user);
        s_axis_tdata  = {a, b, g, r}; // Pack according to our module's mapping
        s_axis_tvalid = 1;
        s_axis_tlast  = last;
        s_axis_tuser  = user;
        
        // Wait for handshake
        wait(s_axis_tready);
        @(posedge clk);
        s_axis_tvalid = 0;
    endtask

    // 4. Stimulus
    initial begin
        // Initialize
        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tuser  = 0;
        s_axis_tlast  = 0;
        m_axis_tready = 1; // Assume downstream is always ready for now

        $display("--- Starting Grayscale Simulation ---");
        repeat(5) @(posedge clk);

        // Test Case 1: Pure Red
        // Math: (77*255 + 150*0 + 29*0) / 256 = 76.7 -> 76 (0x4C)
        send_pixel(8'hFF, 8'h00, 8'h00, 8'hFF, 0, 1); 
        $display("Red Input: Output Data = %h (Expected Gray: 4C)", m_axis_tdata);

        // Test Case 2: Pure Green
        // Math: (77*0 + 150*255 + 29*0) / 256 = 149.4 -> 149 (0x95)
        send_pixel(8'h00, 8'hFF, 8'h00, 8'hFF, 0, 0);
        $display("Green Input: Output Data = %h (Expected Gray: 95)", m_axis_tdata);

        // Test Case 3: Pure Blue
        // Math: (77*0 + 150*0 + 29*255) / 256 = 28.8 -> 28 (0x1C)
        send_pixel(8'h00, 8'h00, 8'hFF, 8'hFF, 0, 0);
        $display("Blue Input: Output Data = %h (Expected Gray: 1C)", m_axis_tdata);

        // Test Case 4: Pure White
        // Math: (77*255 + 150*255 + 29*255) / 256 = 255 (0xFF)
        send_pixel(8'hFF, 8'hFF, 8'hFF, 8'hFF, 1, 0); // End of line
        $display("White Input: Output Data = %h (Expected Gray: FF)", m_axis_tdata);

        repeat(5) @(posedge clk);
        $display("--- Simulation Finished ---");
        $finish;
    end

endmodule