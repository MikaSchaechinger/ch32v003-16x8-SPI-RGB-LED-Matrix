`timescale 1ns / 1ps

module SDPB_sim_tb;

    // Parameter (64 Byte RAM, gleichgroß auf beiden Ports)
    localparam int ADDRESS_DEPTH_A = 8;
    localparam int DATA_WIDTH_A    = 32;
    localparam int ADDRESS_DEPTH_B = 16;
    localparam int DATA_WIDTH_B    = 16;

    // Signale
    logic clka = 0, clkb = 0;
    logic cea, ceb, oce;
    logic reseta, resetb;
    logic [$clog2(ADDRESS_DEPTH_A)-1:0] ada;
    logic [$clog2(ADDRESS_DEPTH_B)-1:0] adb;
    logic [DATA_WIDTH_A-1:0] din;
    logic [DATA_WIDTH_B-1:0] dout;

    // Taktgenerator
    always #5 clka = ~clka;
    always #7 clkb = ~clkb;

    // DUT
    SDPB_sim #(
        .ADDRESS_DEPTH_A(ADDRESS_DEPTH_A),
        .DATA_WIDTH_A(DATA_WIDTH_A),
        .ADDRESS_DEPTH_B(ADDRESS_DEPTH_B),
        .DATA_WIDTH_B(DATA_WIDTH_B)
    ) dut (
        .clka(clka), .cea(cea), .oce(oce), .reseta(reseta), .ada(ada), .din(din),
        .clkb(clkb), .ceb(ceb), .resetb(resetb), .adb(adb), .dout(dout)
    );

    // Testablauf
    integer block;
    logic [31:0] word;
    logic [15:0] expected;

    initial begin
        // Initialwerte
        cea = 0; ceb = 0; oce = 0;
        reseta = 1; resetb = 1;
        din = 0; ada = 0; adb = 0;

        #10 reseta = 0; resetb = 0;

        // Schreibe 8x 32 Bit-Werte
        for (int i = 0; i < ADDRESS_DEPTH_A; i++) begin
            @(posedge clka);
            ada = i;
            din = 32'hDEADBEEF ^ i;
            cea = 1;
        end
        @(posedge clka); cea = 0;

        // Lese 16x 16 Bit-Werte
        @(posedge clkb); ceb = 1; oce = 1;
        for (int j = 0; j < ADDRESS_DEPTH_B; j++) begin
            adb = j;
            @(posedge clkb);
            // Erwarteten Wert berechnen
            block = j / 2;
            word = 32'hDEADBEEF ^ block;

            if (j % 2 == 1)
                expected = word[31:16];
            else
                expected = word[15:0];

            assert(dout === expected)
                else $fatal(1, "Mismatch @ adb=%0d: got %h, expected %h", j, dout, expected);
        end
        ceb = 0;

        $display("[PASS] Alle Lese-/Schreibtests erfolgreich");
        $finish;
    end

endmodule