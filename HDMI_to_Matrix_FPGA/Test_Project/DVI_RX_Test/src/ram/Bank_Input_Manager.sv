module Block_Distributor #(
    parameter int BLOCK_COUNT = 4,          // Number of RAM-blocks in the bank
    parameter int BLOCK_WIDTH = 32,           // Number of RAM-Banks
    parameter int BANDWIDTH = BLOCK_COUNT * BLOCK_WIDTH, // Size of each RAM-block in bits
)(
    input logic [BANDWIDTH-1:0] I_data,     // Data input

    output logic [BLOCK_WIDTH-1:0] O_data [0:BLOCK_COUNT-1], // Data output for each block RAM
);

    // Write I_data to the RAM blocks (apllyed after the O_data_clk)
    always_comb begin
        for (int i = 0; i < BLOCK_COUNT; i++) begin
            O_data[i] = I_data[i*BLOCK_WIDTH +: BLOCK_WIDTH];
        end
    end
endmodule