module Bank_Distributor #(
    parameter int CHANNEL_NUMBER = 3,
    parameter int CHANNEL_BANDWIDTH = 128,
    parameter int BLOCK_DEPTH = 480
)(
    input logic I_clk_in,   // at rise edge of batch_clk_in, the data is valid
    input logic [CHANNEL_BANDWIDTH-1:0] I_data_in [0:CHANNEL_NUMBER-1], // batch data input
    input logic [$clog2(BLOCK_DEPTH) - 1:0] I_address_in, // batch address input

    output logic [CHANNEL_BANDWIDTH-1:0] O_data_out [0:CHANNEL_NUMBER-1], // batch data output
    output logic [$clog2(BLOCK_DEPTH)-1:0] O_address_out [0:CHANNEL_NUMBER-1], // batch address output
    output logic O_clk_out // batch clock output out
);

    // Interne Verbindungen
    logic [$clog2(BLOCK_DEPTH)-1:0] bank_addresses [0:CHANNEL_NUMBER-1];
    logic [$clog2(CHANNEL_NUMBER)-1:0] rotation_offset;

    Buffer_Write_Address_Calculator #(
        .BANK_COUNT(CHANNEL_NUMBER),
        .BLOCK_DEPTH(BLOCK_DEPTH)
    ) addr_calc_inst (
        .I_global_address(I_address_in),
        .O_bank_address(bank_addresses)
    );

    always_comb begin
        // Bestimme Rotation
        rotation_offset = I_address_in % CHANNEL_NUMBER;

        for (int ch = 0; ch < CHANNEL_NUMBER; ch++) begin
            // Rotierte Zuordnung der Daten
            O_data_out[ch]    = I_data_in[(CHANNEL_NUMBER+ch - rotation_offset) % CHANNEL_NUMBER];
            // Lokale Adresse bleibt wie berechnet
            O_address_out[ch] = bank_addresses[ch];
        end

        O_clk_out = I_clk_in;
    end


`ifndef REAL
    `define SIMULATION 0
`endif

    `ifdef SIMULATION
        logic [$clog2(BLOCK_DEPTH)-1:0] bank_address_0;
        logic [$clog2(BLOCK_DEPTH)-1:0] bank_address_1;
        logic [$clog2(BLOCK_DEPTH)-1:0] bank_address_2;

        logic [CHANNEL_BANDWIDTH-1:0] O_data_out_0;
        logic [CHANNEL_BANDWIDTH-1:0] O_data_out_1;
        logic [CHANNEL_BANDWIDTH-1:0] O_data_out_2;


        always_comb begin
            bank_address_0 = O_address_out[0];
            bank_address_1 = O_address_out[1];
            bank_address_2 = O_address_out[2];

            O_data_out_0  = O_data_out[0];
            O_data_out_1  = O_data_out[1];
            O_data_out_2  = O_data_out[2];
        end
    `endif

endmodule
