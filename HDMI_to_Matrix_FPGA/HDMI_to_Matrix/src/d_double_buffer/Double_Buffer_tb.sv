`timescale 1ns / 1ps

module Double_Buffer_tb;

    // === Parameter (an deine DUT angepasst) ===
    localparam int ADDRESS_DEPTH     = 8;
    localparam int BANK_COUNT        = 1;
    localparam int BLOCK_COUNT       = 1;
    localparam int BLOCK_DATA_WIDTH  = 8;
    localparam int BANDWIDTH         = BLOCK_COUNT * BLOCK_DATA_WIDTH;

    // === Signals ===
    logic rst_n;
    logic clka, clk_data_in;
    logic clkb, clk_data_out;
    logic [$clog2(ADDRESS_DEPTH)-1:0] ada [BANK_COUNT-1:0];
    logic [BANDWIDTH-1:0]             din [BANK_COUNT-1:0];
    logic [$clog2(ADDRESS_DEPTH)-1:0] adb [BANK_COUNT-1:0];
    logic [BANDWIDTH*BANK_COUNT-1:0]  dout;
    logic swap_trigger;
    logic data_valid;

    // === Clock generation ===
    initial clka = 0;
    always #5 clka = ~clka; // 100 MHz

    initial clkb = 0;
    always #7 clkb = ~clkb; // ~71 MHz

    // === DUT ===
    Double_Buffer #(
        .ADDRESS_DEPTH(ADDRESS_DEPTH),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH(BLOCK_DATA_WIDTH)
    ) dut (
        .rst_n(rst_n),
        .clka(clka),
        .clk_data_in(clk_data_in),
        .ada(ada),
        .din(din),
        .clkb(clkb),
        .clk_data_out(clk_data_out),
        .adb(adb),
        .dout_flat(dout),
        .swap_trigger(swap_trigger),
        .data_valid(data_valid)
    );

    // === Stimulus ===
    initial begin
        $display("=== Double_Buffer Testbench Start ===");

        // === Initial state ===
        rst_n = 0;
        clk_data_in = 0;
        clk_data_out = 0;
        swap_trigger = 0;
        ada[0] = 0;
        adb[0] = 0;
        din[0] = 0;
        #20;

        rst_n = 1;
        #10;

        // === Write 4 values ===
        for (int i = 0; i < 4; i++) begin
            @(posedge clka);
            ada[0] = i;
            din[0] = 8'hA0 + i; // 0xA0, 0xA1, ...
            clk_data_in = 1;
            @(posedge clka);
            clk_data_in = 0;
        end

        // === Swap Buffers ===
        $display(">> Swap buffers");
        @(posedge clka);
        swap_trigger = 1;
        @(posedge clka);
        swap_trigger = 0;

        // === Wait until data is valid ===
        wait (data_valid == 1);

        // === Read out the same 4 values ===
        for (int i = 0; i < 4; i++) begin
            @(posedge clkb);
            adb[0] = i;
            clk_data_out = 1;
            @(posedge clkb);
            clk_data_out = 0;
            @(posedge clkb); // wait one extra cycle for dout to be valid
            //$display("Read addr %0d: dout = 0x%02h", i, dout[0]);
        end

        $display("=== Test Complete ===");
        #20;
        $finish;
    end

        initial begin
        $dumpfile("Double_Buffer_tb.vcd");
        $dumpvars(0, Double_Buffer_tb);
    end

endmodule
