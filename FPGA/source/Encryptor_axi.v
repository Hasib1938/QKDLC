`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2025 06:33:17 PM
// Design Name: 
// Module Name: Encryptor_axi
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



module Encryptor_axi (
    input clk,
    input rst,
    input [7:0] pixel_in,     // 8-bit pixel input
    input pixel_valid,        // Indicates valid pixel input
    input [7:0] tdata,        // 8-bit key from AXI-Stream
    input tvalid,             // Key valid signal
    output reg tready,        // Ready to receive key
    output reg [7:0] pixel_out, // 8-bit encrypted pixel output
    output reg done
);

    reg [31:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            done <= 0;
            pixel_out <= 0;
            tready <= 1'b1;  // Always ready to receive keys
        end 
        else if (pixel_valid && tvalid) begin
            pixel_out <= pixel_in ^ tdata; // XOR encryption
            count <= count + 1;

            if (count == (512*512*3)) 
                done <= 1;
        end
    end
endmodule

