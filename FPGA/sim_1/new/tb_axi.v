`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2025 06:41:26 PM
// Design Name: 
// Module Name: tb_axi
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

module Encryptor_AXIStream_tb();
    reg clk, rst;
    reg [7:0] pixel_in;
    wire [7:0] pixel_out;
    reg pixel_valid;
    wire done;
    reg key_valid;
    reg [7:0] key_in;           // Key read from external file
    wire [7:0] key_out;
    wire tvalid;
    wire tready;

    integer key_file, file_in, file_out, i, key_read;

    // Instantiate Lorenz Module (AXI-Stream Master)
    Lorenz_axi lorenz_inst (
        .clk(clk),
        .rst(rst),
        .key_valid(key_valid),
        .key_in(key_in),           // Key read from external file
        .tdata(key_out),
        .tvalid(tvalid),
        .tready(tready)
    );

    // Instantiate Encryptor Module (AXI-Stream Slave)
    Encryptor_axi encryptor_inst (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .tdata(key_out),
        .tvalid(tvalid),
        .tready(tready),
        .pixel_out(pixel_out),
        .done(done)
    );

    always #5 clk = ~clk;  // Clock generation

    initial begin
        clk = 0;
        rst = 1;
        pixel_valid = 0;
        key_valid = 0;
        key_in = 0;
        #10 rst = 0;

        // Open key file and read the key
        key_file = $fopen("checkerboard_key_all.txt", "r");
        if (key_file == 0) begin
            $display("Error: Could not open key.txt!");
            $stop;
        end

        // Open input BMP file and output encrypted BMP file
        file_in = $fopen("lena_color.bmp", "rb");
        file_out = $fopen("output_encrypted.bmp", "wb");

        if (file_in == 0 || file_out == 0) begin
            $display("Error: Could not open image files!");
            $stop;
        end

        // **Write BMP Header (First 54 bytes) directly**
        for (i = 0; i < 54; i = i + 1) begin
            pixel_in = $fgetc(file_in);
            $fwrite(file_out, "%c", pixel_in);  // Write header to output
        end

        pixel_valid = 1;  // Enable pixel processing

        // **Process Pixel Data**
        for (i = 54; i < (512*512*3 + 54); i = i + 1) begin
            pixel_in = $fgetc(file_in);
            #10;  // Wait for encryption
            $fwrite(file_out, "%c", pixel_out);

            // Read new key from file whenever needed
            if (!$feof(key_file)) begin
                key_read = $fscanf(key_file, "%h\n", key_in);
                key_valid = 1;  // Enable key signal to pass it to Lorenz
            end
            else begin
                key_valid = 0;  // Disable key signal if EOF reached
            end

            $display("Time %0t: Encrypted pixel: %h using key: %h", $time, pixel_out, key_out);
        end

        pixel_valid = 0;  // Disable pixel processing

        // Close files after processing
        $fclose(file_in);
        $fclose(file_out);
        $fclose(key_file);

        $display("Encryption complete.");
        $stop;
    end
endmodule

