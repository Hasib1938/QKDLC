`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2025 10:11:28 PM
// Design Name: 
// Module Name: top_testbench
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
module Lorenz_Encryptor_Top_tb;
    reg clk, rst;
    reg s_axis_key_tvalid;
    reg [7:0] s_axis_key_tdata;
    reg s_axis_pixel_tvalid;
    reg [7:0] s_axis_pixel_tdata;
    wire [7:0] m_axis_pixel_tdata;
    wire done;
    wire s_axis_key_tready;
    wire [7:0] m_axis_key_tdata;
    wire m_axis_key_tvalid;
    wire s_axis_pixel_tready;
    wire m_axis_pixel_tvalid;
    reg m_axis_pixel_tready;

    integer key_file, file_in, file_out, i, key_read, key_out_file;

    // Instantiate Lorenz_Encryptor_Top module
    Lorenz_Encryptor_Top top_inst (
        .clk(clk),
        .rst(rst),

        // AXI-Stream Key Interface
        .s_axis_key_tdata(s_axis_key_tdata),
        .s_axis_key_tvalid(s_axis_key_tvalid),
        .s_axis_key_tready(s_axis_key_tready),

        .m_axis_key_tdata(m_axis_key_tdata),
        .m_axis_key_tvalid(m_axis_key_tvalid),
        .m_axis_key_tready(s_axis_key_tready),  // Connect ready back to key stream

        // AXI-Stream Pixel Interface
        .s_axis_pixel_tdata(s_axis_pixel_tdata),
        .s_axis_pixel_tvalid(s_axis_pixel_tvalid),
        .s_axis_pixel_tready(s_axis_pixel_tready),

        .m_axis_pixel_tdata(m_axis_pixel_tdata),
        .m_axis_pixel_tvalid(m_axis_pixel_tvalid),
        .m_axis_pixel_tready(m_axis_pixel_tready),

        // Done signal
        .done(done)
    );

    always #5 clk = ~clk;  // Clock generation

    initial begin
        clk = 0;
        rst = 1;
        s_axis_key_tvalid = 0;
        s_axis_pixel_tvalid = 0;
        s_axis_key_tdata = 0;
        m_axis_pixel_tready = 1; // Consumer always ready to receive pixels

        #10 rst = 0;

        // Open key file
        key_file = $fopen("gradient_key_all.txt", "r");
        if (key_file == 0) begin
            $display("Error: Could not open key file!");
            $stop;
        end

        // Open input BMP file and output encrypted BMP file
        file_in = $fopen("Image.bmp", "rb");
        file_out = $fopen("encrypted_image.bmp", "wb");
        key_out_file = $fopen("output_gradient_key.txt", "w"); // New file for storing output key

        if (file_in == 0 || file_out == 0 || key_out_file == 0) begin
            $display("Error: Could not open image or key output files!");
            $stop;
        end

        // **Write BMP Header (First 54 bytes) directly**
        for (i = 0; i < 54; i = i + 1) begin
            s_axis_pixel_tdata = $fgetc(file_in);
            $fwrite(file_out, "%c", s_axis_pixel_tdata);  // Write header to output file
        end

        s_axis_pixel_tvalid = 1;  // Enable pixel processing

        // **Process Pixel Data**
        for (i = 54; i < (512*512*3 + 54); i = i + 1) begin
            s_axis_pixel_tdata = $fgetc(file_in);  // Read pixel from input file

            // **Read new key from file**
            if (!$feof(key_file)) begin
                key_read = $fscanf(key_file, "%h\n", s_axis_key_tdata);  // Read 8-bit key from file
                s_axis_key_tvalid = 1;  // Enable key transmission
            end
            else begin
                s_axis_key_tvalid = 0;  // Stop sending key
            end

            // Wait for AXI handshaking
            wait (s_axis_key_tready && s_axis_pixel_tready);
            #10;  // Simulate pipeline delay

            $fwrite(file_out, "%c", m_axis_pixel_tdata);  // Write encrypted pixel to output file
            $fwrite(key_out_file, "%h\n", m_axis_key_tdata);  // Write output key to file

            $display("Time %0t: Encrypted pixel: %h using key: %h", $time, m_axis_pixel_tdata, m_axis_key_tdata);
        end

        s_axis_pixel_tvalid = 0;  // Stop pixel processing
        s_axis_key_tvalid = 0;  // Stop key transmission

        // Close files after processing
        $fclose(file_in);
        $fclose(file_out);
        $fclose(key_file);
        $fclose(key_out_file);

        $display("Encryption complete. Output keys stored in output_key_log.txt");
        $stop;
    end
endmodule

