
module Sync_Manager_tb;

    // Parameter
    localparam H_ACTIVE = 4;
    localparam H_TOTAL  = 16;
    localparam V_ACTIVE = 4;
    localparam V_TOTAL  = 16;
    localparam DELAY    = 10;

    // Testbench-Signale
    logic rst_n;
    logic clk;

    logic [3:0] pll_phase;
    logic       pll_phase_lock;
    logic       rgb_clk;
    logic       rgb_vs;
    logic       rgb_hs;
    logic       rgb_de;
    logic [7:0] rgb_r;
    logic [7:0] rgb_g;
    logic [7:0] rgb_b;

    logic [$clog2(1920)-1:0] image_width;
    logic [$clog2(1080)-1:0] image_height;
    logic                        width_valid;
    logic                        height_valid;
    logic                        new_row;
    logic                        new_frame;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // === DVI_RX_Wrapper Simulation ===
    DVI_RX_Wrapper #(
        .H_ACTIVE(H_ACTIVE),
        .H_TOTAL(H_TOTAL),
        .V_ACTIVE(V_ACTIVE),
        .V_TOTAL(V_TOTAL)
    ) dvi_rx (
        .I_rst_n(rst_n),
        .I_tmds_clk_p(1'b0),
        .I_tmds_clk_n(1'b0),
        .I_tmds_data_p(3'b000),
        .I_tmds_data_n(3'b000),
        .clk(clk),

        .O_pll_phase(pll_phase),
        .O_pll_phase_lock(pll_phase_lock),
        .O_rgb_clk(rgb_clk),
        .O_rgb_vs(rgb_vs),
        .O_rgb_hs(rgb_hs),
        .O_rgb_de(rgb_de),
        .O_rgb_r(rgb_r),
        .O_rgb_g(rgb_g),
        .O_rgb_b(rgb_b)
    );

    // === DUT ===
    Sync_Manager #(
        .MAX_WIDTH(1920),
        .MAX_HEIGHT(1080),
        .DELAY(DELAY)
    ) dut (
        .I_rst_n(rst_n),
        .I_rgb_clk(rgb_clk),
        .I_rgb_de(rgb_de),
        .I_rgb_hsync(rgb_hs),
        .I_rgb_vsync(rgb_vs),
        .O_image_width(image_width),
        .O_image_height(image_height),
        .O_width_valid(width_valid),
        .O_height_valid(height_valid),
        .O_new_row(new_row),
        .O_new_frame(new_frame)
    );

    // === Stimulus ===
    initial begin
        $display("=== Testbench Start ===");
        rst_n = 0;
        #50;
        rst_n = 1;

        //wait (height_valid && width_valid);
        #100000;

        $finish;
    end

    
    initial begin
        $dumpfile("Sync_Manager_tb.vcd");
        $dumpvars(0, Sync_Manager_tb);
    end

endmodule
