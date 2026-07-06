`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2026 02:47:06 PM
// Design Name: 
// Module Name: img_rom
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module image_rom (
    input  wire        clk,
    input  wire [16:0] addr,
    output reg  [7:0]  dout
);
    reg [7:0] mem [0:76799];
    initial $readmemh("image_data.hex", mem);
    
    always @(posedge clk)
        dout <= mem[addr];
endmodule