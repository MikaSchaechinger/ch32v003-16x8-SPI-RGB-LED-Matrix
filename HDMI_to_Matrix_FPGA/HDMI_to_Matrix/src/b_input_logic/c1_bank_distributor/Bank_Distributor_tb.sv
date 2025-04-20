
`timescale 1ns / 1ps

module Bank_Distributor_tb;

    localparam int CHANNEL_NUMBER    = 3;
    localparam int CHANNEL_BANDWIDTH = 8;   // 8 Bytes write at once
    localparam int CHANNEL_DEPTH     = 4;
    localparam int BLOCK_DEPTH        = CHANNEL_DEPTH * CHANNEL_NUMBER;  // How many times fit CHANNEL_BANDWIDTH in BLOCK_DEPTH?
    localparam int GLOBAL_ADDR_BITS  = $clog2(BLOCK_DEPTH * CHANNEL_NUMBER);
    localparam int BANK_ADDR_BITS    = $clog2(BLOCK_DEPTH);

    // DUT I/O
    logic I_clk_in;
    logic [CHANNEL_BANDWIDTH-1:0] I_data_in     [0:CHANNEL_NUMBER-1];
    logic [GLOBAL_ADDR_BITS-1:0]  I_address_in;
    logic [CHANNEL_BANDWIDTH-1:0] O_data_out    [0:CHANNEL_NUMBER-1];
    logic [BANK_ADDR_BITS-1:0]    O_address_out [0:CHANNEL_NUMBER-1];
    logic                         O_clk_out     [0:CHANNEL_NUMBER-1];

    // DUT
    Bank_Distributor #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .CHANNEL_BANDWIDTH(CHANNEL_BANDWIDTH),
        .BLOCK_DEPTH(BLOCK_DEPTH)
    ) dut (
        .I_clk_in(I_clk_in),
        .I_data_in(I_data_in),
        .I_address_in(I_address_in),
        .O_data_out(O_data_out),
        .O_address_out(O_address_out),
        .O_clk_out(O_clk_out)
    );

    initial begin
        I_data_in[0] = 8'hFF;
        I_data_in[1] = 8'h55;
        I_data_in[2] = 8'h00;

        for (int i = 0; i < BLOCK_DEPTH; i++) begin
            I_address_in = i;
            #1;
        end


    end

    initial begin
        $dumpfile("Bank_Distributor_tb.vcd");
        $dumpvars(0, Bank_Distributor_tb);
    end

endmodule
