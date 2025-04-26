
`timescale 1ns/1ps

module Input_Logic_tb;

    // === Parameter ===
    localparam COLOR_COUNT = 3;
    localparam BATCH_SIZE = 4;
    localparam MAX_WIDTH = 64;
    localparam MAX_HEIGHT = 64;
    localparam BLOCK_WIDTH = 32;
    localparam BLOCK_DEPTH = 480;

    localparam IMAGE_WIDTH = 16;
    localparam IMAGE_HEIGHT = 8;

    // === DUT Ports ===
    logic rst_n;
    logic rgb_clk;
    logic rgb_de;
    logic rgb_hs;
    logic rgb_vs;
    logic [7:0] rgb_color [0:COLOR_COUNT-1];

    logic [8*BATCH_SIZE-1:0] data_distributed [COLOR_COUNT-1:0];
    logic [8*BATCH_SIZE-1:0] data_distributed_0;
    assign data_distributed_0 = data_distributed[0];
    logic [$clog2(BLOCK_DEPTH)-1:0] address_distributed [COLOR_COUNT-1:0];
    logic [$clog2(BLOCK_DEPTH)-1:0] address_distributed_0;
    assign address_distributed_0 = address_distributed[0];
    logic clk_distributed;

    logic [$clog2(MAX_WIDTH)-1:0] image_width;
    logic [$clog2(MAX_HEIGHT)-1:0] image_height;
    logic image_valid;

    // === Clock Generation ===
    initial rgb_clk = 0;
    always #5 rgb_clk = ~rgb_clk;

    // === DUT Instanz ===
    Input_Logic #(
        .CHANNEL_COUNT(COLOR_COUNT),
        .BATCH_SIZE(BATCH_SIZE),
        .BLOCK_WIDTH(BLOCK_WIDTH),
        .BLOCK_DEPTH(BLOCK_DEPTH),
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_HEIGHT(MAX_HEIGHT)
    ) dut (
        .rst_n(rst_n),
        .rgb_clk(rgb_clk),
        .rgb_de(rgb_de),
        .rgb_hs(rgb_hs),
        .rgb_vs(rgb_vs),
        .rgb_color(rgb_color),
        .data_distributed(data_distributed),
        .address_distributed(address_distributed),
        .clk_distributed(clk_distributed),
        .image_width(image_width),
        .image_height(image_height),
        .image_valid(image_valid)
    );

    // === Teststimulus ===
    initial begin
        $display("=== Input_Logic TB Start ===");
        rst_n = 0;
        rgb_de = 0;
        rgb_hs = 1;
        rgb_vs = 1;
        rgb_color[0] = 8'h00;
        rgb_color[1] = 8'hBB;
        rgb_color[2] = 8'hCC;
        #20;

        rst_n = 1;
        #20;

        repeat (4) begin // 4 Images
            rgb_color[0] = 8'h00;
        // Simuliere ein 4x3 Bild
            repeat (IMAGE_HEIGHT) begin // 3 Zeilen
                rgb_hs = 0; #10; rgb_hs = 1;
                repeat (IMAGE_WIDTH) begin // 4 Pixel
                    rgb_de = 1;
                    rgb_color[0] = rgb_color[0] + 1;
                    #10;
                end
                rgb_de = 0;
                #20;
            end

            // Frame-Ende mit VSYNC
            rgb_vs = 0; #10; rgb_vs = 1;
        end
        #50;

        $display("Image width: %0d, height: %0d, valid: %b",
                 image_width, image_height, image_valid);
        $display("=== Input_Logic TB Done ===");
        $finish;
    end

    initial begin
        $dumpfile("Input_Logic_tb.vcd");
        $dumpvars(0, Input_Logic_tb);
    end
endmodule
