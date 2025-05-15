`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2025 06:32:31 PM
// Design Name: 
// Module Name: Lorenz_module
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

module Lorenz_axi (
    input clk,
    input rst,
    input key_valid,         // Signal to enable perturbation
    input [7:0] key_in,      // 8-bit key affecting Lorenz parameters
    output reg [7:0] tdata,  // 8-bit key output
    output reg tvalid,       // Data valid signal
    input tready             // Ready signal from receiver (Encryptor)
);

    // Fixed-point representation (Fix24_20: 24-bit integer, 20-bit fraction)
    reg signed [43:0] x, y, z;
    reg signed [43:0] x_next, y_next, z_next;
    
    // Lorenz system constants (scaled by 2^20 for precision)
    reg signed [43:0] a, b, c;
    localparam signed [43:0] T = 44'sd10486; // T = 0.01 * 2^20
    reg [1:0] key_select;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 44'sd1048576;  // Initial conditions
            y <= 44'sd2097152;
            z <= 44'sd3145728;
            a <= 44'sd10485760;
            b <= 44'sd29360128;
            c <= 44'sd87381;
            key_select <= 2'b00;
            tvalid <= 0;
        end 
        else begin
            if (key_valid) begin
                a <= 44'sd10485760 + (key_in[7:0] << 12);
                b <= 44'sd29360128 + (key_in[7:0] << 12);
                c <= 44'sd87381 + (key_in[7:0] << 12);
            end

            // Euler method for next state calculation
            x_next = x + ((T * (a * (y - x) >> 20)) >> 20);
            y_next = y + ((T * ((b * x >> 20) - (x * z >> 20) - y) >> 20));
            z_next = z + ((T * ((x * y >> 20) - (c * z >> 20)) >> 20));

            x <= x_next;
            y <= y_next;
            z <= z_next;

            // Select which variable to send via AXI-Stream
            case (key_select)
                2'b00: tdata <= x_next[7:0];
                2'b01: tdata <= y_next[7:0];
                2'b10: tdata <= z_next[7:0];
            endcase

            key_select <= key_select + 1;
            tvalid <= 1'b1;  // Key is valid

            // Only move to the next key when Encryptor is ready
            if (tready)
                tvalid <= 1'b1;
        end
    end

endmodule
