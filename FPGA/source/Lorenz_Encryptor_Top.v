`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2025 10:09:06 PM
// Design Name: 
// Module Name: Lorenz_Encryptor_Top
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
module Lorenz_Encryptor_Top (
    input wire clk,
    input wire rst,

    // AXI-Stream Slave Interface for Key Data (External Master -> Lorenz_Encryptor_Top)
    input wire [7:0]  s_axis_key_tdata,   // Key input data
    input wire        s_axis_key_tvalid,  // Key valid signal
    output wire       s_axis_key_tready,  // Ready signal to external master

    // AXI-Stream Master Interface for Key Data (Lorenz_Encryptor_Top -> Encryptor)
    output wire [7:0] m_axis_key_tdata,   // Key output data
    output wire       m_axis_key_tvalid,  // Key valid signal
    input wire        m_axis_key_tready,  // Ready signal from Encryptor

    // AXI-Stream Slave Interface for Pixel Data (External Master -> Lorenz_Encryptor_Top)
    input wire [7:0]  s_axis_pixel_tdata,  // Pixel input data
    input wire        s_axis_pixel_tvalid, // Pixel valid signal
    output wire       s_axis_pixel_tready, // Ready signal to external master

    // AXI-Stream Master Interface for Encrypted Pixels (Lorenz_Encryptor_Top -> External Consumer)
    output wire [7:0] m_axis_pixel_tdata,  // Encrypted pixel output
    output wire       m_axis_pixel_tvalid, // Pixel valid signal
    input wire        m_axis_pixel_tready, // Ready signal from external consumer

    // Encryption Done Signal
    output wire done
);

    // Internal Wires
    wire [7:0] key_data_out;
    wire key_valid_out;
    wire key_ready_in;

    // Instantiate Lorenz Module (AXI-Stream Master for Key Generation)
    Lorenz_axi lorenz_inst (
        .clk(clk),
        .rst(rst),
        .key_valid(s_axis_key_tvalid),   // Receiving key from external source
        .key_in(s_axis_key_tdata),       // Key data input
        .tdata(key_data_out),            // Key output data
        .tvalid(key_valid_out),          // Key valid signal
        .tready(key_ready_in)            // Ready signal from Encryptor
    );

    // Instantiate Encryptor Module (AXI-Stream Slave for Pixel Encryption)
    Encryptor_axi encryptor_inst (
        .clk(clk),
        .rst(rst),
        .pixel_in(s_axis_pixel_tdata),   // Receiving pixel data
        .pixel_valid(s_axis_pixel_tvalid),
        .tdata(key_data_out),            // Key data from Lorenz
        .tvalid(key_valid_out),          // Key valid signal from Lorenz
        .tready(key_ready_in),           // Ready signal from Encryptor
        .pixel_out(m_axis_pixel_tdata),  // Encrypted pixel output
        .done(done)
    );

    // AXI-Stream Handshaking Logic
    assign s_axis_key_tready  = key_ready_in;  // Ready when Encryptor is ready
    assign m_axis_key_tdata   = key_data_out;  // Pass generated key to Encryptor
    assign m_axis_key_tvalid  = key_valid_out; // Valid signal to Encryptor

    assign s_axis_pixel_tready = m_axis_pixel_tready;  // Ready when output is ready
    assign m_axis_pixel_tvalid = s_axis_pixel_tvalid;  // Pass valid signal

endmodule

