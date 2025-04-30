module Single_Buffer #(
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BANK_COUNT = 6,
    parameter int BLOCK_COUNT = 2,
    parameter int BLOCK_DATA_WIDTH_A = 32,  // Write Port
    parameter int BLOCK_DATA_WIDTH_B = 8,   // Read Port
    parameter int BANDWIDTH_A = BANK_COUNT * BLOCK_DATA_WIDTH_A, // Write Port
    parameter int BANDWIDTH_B = BANK_COUNT * BLOCK_DATA_WIDTH_B, // Read Port
    parameter int ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A, // Write Port
    parameter int ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B // Read Port
)(
    input  logic                         I_clka,
    input  logic                         I_cea,
    input  logic                         I_oce,
    input  logic                         I_reseta,
    input  logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_A)-1:0] I_ada_flat,
    input  logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_A-1:0]       I_din_flat,

    input  logic                         I_clkb,
    input  logic                         I_ceb,
    input  logic                         I_resetb,
    input  logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_B)-1:0] I_adb_flat,
    output logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0]       O_dout_flat
);

    // Internal arrays
    logic [BLOCK_COUNT*$clog2(ADDRESS_NUMBER_A)-1:0] ada_bank [BANK_COUNT-1:0];
    logic [BLOCK_COUNT*BLOCK_DATA_WIDTH_A-1:0]       din_bank [BANK_COUNT-1:0];
    logic [BLOCK_COUNT*$clog2(ADDRESS_NUMBER_B)-1:0] adb_bank [BANK_COUNT-1:0];
    logic [BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0]       dout_bank [BANK_COUNT-1:0];

    // Connect Input Ports
    always_comb begin
        for (int bank = 0; bank < BANK_COUNT; bank++) begin
            for (int block = 0; block < BLOCK_COUNT; block++) begin
                din_bank[bank][block*BLOCK_DATA_WIDTH_A +: BLOCK_DATA_WIDTH_A] = I_din_flat[bank*BLOCK_COUNT*BLOCK_DATA_WIDTH_A + block*BLOCK_DATA_WIDTH_A +: BLOCK_DATA_WIDTH_A];
                ada_bank[bank][block*$clog2(ADDRESS_NUMBER_A) +: $clog2(ADDRESS_NUMBER_A)] = I_ada_flat[bank*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_A) + block*$clog2(ADDRESS_NUMBER_A) +: $clog2(ADDRESS_NUMBER_A)];
                adb_bank[bank][block*$clog2(ADDRESS_NUMBER_B) +: $clog2(ADDRESS_NUMBER_B)] = I_adb_flat[bank*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_B) + block*$clog2(ADDRESS_NUMBER_B) +: $clog2(ADDRESS_NUMBER_B)];
            end
        end
    end


    genvar bank;
    generate
        for (bank = 0; bank < BANK_COUNT; bank++) begin : bank_gen
            Bank #(
                .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
                .BLOCK_COUNT(BLOCK_COUNT),
                .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
                .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
            ) bank_inst (
                .I_clka(I_clka),
                .I_cea(I_cea),
                .I_oce(I_oce),
                .I_reseta(I_reseta),
                .I_ada_flat(ada_bank[bank]),
                .I_din_flat(din_bank[bank]),
                .I_clkb(I_clkb),
                .I_ceb(I_ceb),
                .I_resetb(I_resetb),
                .I_adb_flat(adb_bank[bank]),
                .O_dout_flat(dout_bank[bank])
            );
        end
    endgenerate

    // Connect Output Ports
    always_comb begin
        for (int i = 0; i < BANK_COUNT; i++) begin
            O_dout_flat[i*BLOCK_COUNT*BLOCK_DATA_WIDTH_B +: BLOCK_COUNT*BLOCK_DATA_WIDTH_B] = dout_bank[i];
        end
    end

endmodule