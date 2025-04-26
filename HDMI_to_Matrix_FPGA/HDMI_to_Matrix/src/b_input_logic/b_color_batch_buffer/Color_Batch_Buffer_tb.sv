`timescale 1ns / 1ps

module Color_Batch_Buffer_tb;

    // Parameter
    localparam int BATCH_SIZE = 8;

    // Clock & Reset
    logic rgb_clk = 0;
    logic rst_n = 0;

    // Inputs
    logic [7:0] I_color;
    logic       I_color_valid;

    // Outputs
    logic       batch_ready;
    logic       batch_clk_out;
    logic [8*BATCH_SIZE-1:0] batch_color;

    // Clock Generator (e.g. 50 MHz)
    always #10 rgb_clk = ~rgb_clk;

    // DUT
    Color_Batch_Buffer #(
        .BATCH_SIZE(BATCH_SIZE)
    ) dut (
        .I_rgb_clk        (rgb_clk),
        .I_rst_n          (rst_n),
        .I_color        (I_color),
        .I_color_valid  (I_color_valid),
        .O_batch_ready  (batch_ready),
        .O_batch_clk_out (batch_clk_out),
        .O_batch_color  (batch_color)
    );

    int unsigned color_counter = 0;

    // Stimulus
    initial begin
        // Reset
        I_color        = 0;
        I_color_valid  = 0;
        #50;
        rst_n = 1;
        #20;

        // Send zwei vollständige Batches


        repeat (4) begin
            for (int i = 0; i < BATCH_SIZE; i++) begin

                @(negedge rgb_clk);
                I_color       = color_counter[7:0];
                color_counter++;
                I_color_valid = 1;
            end
            // @(posedge rgb_clk);
            // I_color_valid = 0;
            // #100;
        end


        // Simulation beenden
        #100;
        $finish;
    end

    // VCD-Output für GTKWave / iverilog
    initial begin
        $dumpfile("Color_Batch_Buffer_tb.vcd");
        $dumpvars(0, Color_Batch_Buffer_tb);
    end

endmodule
