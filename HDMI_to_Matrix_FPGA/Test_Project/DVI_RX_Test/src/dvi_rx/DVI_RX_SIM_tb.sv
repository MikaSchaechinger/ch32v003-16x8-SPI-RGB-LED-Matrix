`timescale 1ns / 1ps

module DVI_RX_SIM_tb;

    // Signale
    logic clk;
    logic rst_n;

    // DVI_RX_SIM Outputs
    logic [3:0] O_pll_phase;
    logic       O_pll_phase_lock;
    logic       O_rgb_clk;
    logic       O_rgb_vs;
    logic       O_rgb_hs;
    logic       O_rgb_de;
    logic [7:0] O_rgb_r;
    logic [7:0] O_rgb_g;
    logic [7:0] O_rgb_b;

    // Taktgenerator: 50 MHz (Periode 20 ns)
    initial clk = 0;
    always #10 clk = ~clk;

    // Reset
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // Instanz des DUT (kleine Auflösung für schnellen Durchlauf)
    DVI_RX_SIM #(
        .H_ACTIVE(128),
        .H_TOTAL(144),
        .V_ACTIVE(32),
        .V_TOTAL(40)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .O_pll_phase(O_pll_phase),
        .O_pll_phase_lock(O_pll_phase_lock),
        .O_rgb_clk(O_rgb_clk),
        .O_rgb_vs(O_rgb_vs),
        .O_rgb_hs(O_rgb_hs),
        .O_rgb_de(O_rgb_de),
        .O_rgb_r(O_rgb_r),
        .O_rgb_g(O_rgb_g),
        .O_rgb_b(O_rgb_b)
    );

    // Simulationsdauer begrenzen
    initial begin
        #1_000_000;  // 1 ms Simulation (~25 volle Frames bei 25 MHz Pixelclock)
        $finish;
    end

    initial begin
        $dumpfile("DVI_RX_SIM_tb.vcd");
        $dumpvars(0, DVI_RX_SIM_tb);
    end

endmodule
