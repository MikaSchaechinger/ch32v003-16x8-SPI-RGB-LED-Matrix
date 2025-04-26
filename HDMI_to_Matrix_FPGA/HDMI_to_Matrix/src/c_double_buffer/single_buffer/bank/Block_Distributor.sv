module Block_Distributor #(
    parameter BLOCK_COUNT = 4, // Number of blocks to distribute data to
    parameter BLOCK_DATA_WIDTH = 32, // Data width for each block
    parameter BANDWIDTH = BLOCK_COUNT * BLOCK_DATA_WIDTH // Total bandwidth
)(
    input logic [BANDWIDTH-1:0] data_in, // Input data
    output logic [BLOCK_DATA_WIDTH-1:0] data_out [BLOCK_COUNT-1:0] // Output data for each block
);


    // Distribute the input data to each block
    always_comb begin
        for (int i = 0; i < BLOCK_COUNT; i++) begin
            data_out[i] = data_in[(i+1)*BLOCK_DATA_WIDTH-1 -: BLOCK_DATA_WIDTH];
        end
    end


endmodule