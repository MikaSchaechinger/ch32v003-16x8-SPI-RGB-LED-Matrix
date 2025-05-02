module Matrix_Buffer #(
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BANK_COUNT = 6,
    parameter int BLOCK_COUNT = 2,
    parameter int BLOCK_DATA_WIDTH_A = 32,  // Write Port
    parameter int BLOCK_DATA_WIDTH_B = 8,   // Read Port
    parameter int ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A,
    parameter int ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B // Read Port
)(
    // Common Signals
    input  logic                         I_rst_n,
    input  logic                         I_swap_trigger,             // z. B. bei frame_complete
    // Input Side
    input  logic                         I_clka,
    input  logic                         I_write_enable,
    input  logic [$clog2(ADDRESS_NUMBER_A)-1:0] I_write_address,
    input  logic [(BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_A-1:0] I_data_flat,

    // Output Side
    input  logic                         I_clkb,
    input  logic                         I_read_enable,
    input  logic [$clog2(ADDRESS_NUMBER_B)-1:0] I_read_address,
    output logic [(BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_B-1:0] O_data_flat,
    
    output logic                         O_data_valid                // High after first swap_trigger
);

    logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_A)-1:0] write_addresses_flat;
    logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_A-1:0] write_data_flat;


    logic [$clog2(ADDRESS_NUMBER_B)-1:0] read_address_single;
    logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_B)-1:0] read_addresses_flat;
    logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0] read_data_flat;

    Input_Port #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A)
    ) input_port_inst (
        .I_address(I_write_address),
        .I_data_flat(I_data_flat),
        .O_addresses_flat(write_addresses_flat),
        .O_data_flat(write_data_flat)
    );


    Double_Buffer #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) buffer_inst (
        .I_rst_n(I_rst_n),
        .I_clka(I_clka),
        .I_write_enable(I_write_enable),
        .I_ada_flat(write_addresses_flat),
        .I_din_flat(write_data_flat),

        .I_clkb(I_clkb),
        .I_read_enable(I_read_enable),
        .I_adb_flat(read_addresses_flat),
        .O_dout_flat(read_data_flat),

        .I_swap_trigger(I_swap_trigger),
        .O_data_valid(O_data_valid)
    );


    Output_Port #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) output_port_inst (
        .I_rst_n(I_rst_n),
        .I_clkb(I_clkb),
        .O_addresses_common(read_address_single),
        .I_data_flat(read_data_flat),

        .I_address(I_read_address),
        .O_data_flat(O_data_flat)
    );
        

    // Connect read_address_single to read_addresses_flat
    always_comb begin
        for (int i = 0; i < BANK_COUNT*BLOCK_COUNT; i++) begin
            read_addresses_flat[i*$clog2(ADDRESS_NUMBER_B) +: $clog2(ADDRESS_NUMBER_B)] = read_address_single;
        end
    end


endmodule