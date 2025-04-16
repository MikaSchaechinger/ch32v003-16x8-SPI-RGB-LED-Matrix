module Single_Buffer #(
    parameter int BLOCK_COUNT = 4,          // Number of RAM-blocks in the bank
    parameter int BANK_COUNT = 3,           // Number of RAM-Banks


    parameter int BANK_INDEX = 0,           // Colors get shifteted by the index, so they can be read/written in parallel from multiple Banks
    parameter int PANEL_WIDTH = 8,          // Width of the panel in pixels
    parameter int PANEL_HEIGHT = 16,         // Height of the panel in pixels
    parameter int COLOR_COUNT = 3,          // Number of colors (RGB)
    parameter int BLOCK_COUNT = 4,          // Number of RAM-blocks in the bank
    parameter int BLOCK_DEPTH = 512,        // Depth of each RAM-block
    parameter int BLOCK_WIDTH = 32,         // Width of each RAM-block
    parameter int BLOCK_SIZE = BLOCK_DEPTH * BLOCK_WIDTH, // Size of each RAM-block in bits
    parameter int BANDWIDTH = BLOCK_COUNT * BLOCK_WIDTH,
    parameter int OUTSIDE_ADDRESS_WIDTH = $clog2(BLOCK_SIZE/BLOCK_WIDTH) // Address width for the outside RAMs
)(

);







genvar bank, block;
generate
    for (bank = 0; bank < BANK_COUNT; bank++) begin : gen_bank

        // Create a Block Distributor for each bank
        Block_Distributor #(
            .BLOCK_COUNT(BLOCK_COUNT),
            .BLOCK_WIDTH(BLOCK_WIDTH),
            .BANDWIDTH(BANDWIDTH)
        ) block_distributor (
            .I_data(), // Data input
            .O_data()  // Data output for each block RAM
        );


        for (block = 0; block < BLOCK_COUNT; block++) begin : gen_block

            // Create a RAM for each block in the bank
            SDPB_sim #(
                .ADDRESS_DEPTH_A(480), // max 512, but must be dividable by 3 and 32. Result is 5 Panels per Block
                .DATA_WIDTH_A(32),
                .ADDRESS_DEPTH_B(480),
                .DATA_WIDTH_B(32)
            ) ram (
                .clka(), // Clock A
                .cea(),  // Chip Enable A
                .oce(),  // Output Clock Enable A
                .reseta(), // Reset A
                .ada(),  // Address A
                .din(),  // Data Input A

                .clkb(), // Clock B
                .ceb(),  // Chip Enable B
                .resetb(), // Reset B
                .adb(),  // Address B
                .dout()  // Data Output B
            );
        end
    end
endgenerate









endmodule