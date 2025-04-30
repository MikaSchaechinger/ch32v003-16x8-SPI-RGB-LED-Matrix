module Bank #(
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BLOCK_COUNT = 2,
    parameter int BLOCK_DATA_WIDTH_A = 32,  // Write Port
    parameter int BLOCK_DATA_WIDTH_B = 8,   // Read Port
    parameter int BANDWIDTH_A = BLOCK_COUNT * BLOCK_DATA_WIDTH_A, // Write Port
    parameter int BANDWIDTH_B = BLOCK_COUNT * BLOCK_DATA_WIDTH_B, // Read Port
    parameter int ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A, // Write Port
    parameter int ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B // Read Port
)(
    input  logic                        I_clka,
    input  logic                        I_cea,
    input  logic                        I_oce,
    input  logic                        I_reseta,
    input  logic [BLOCK_COUNT*$clog2(ADDRESS_NUMBER_A)-1:0] I_ada_flat,
    input  logic [BLOCK_COUNT*BLOCK_DATA_WIDTH_A-1:0] I_din_flat,

    input  logic                        I_clkb,
    input  logic                        I_ceb,
    input  logic                        I_resetb,
    input  logic [BLOCK_COUNT*$clog2(ADDRESS_NUMBER_B)-1:0] I_adb_flat,
    output logic [BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0] O_dout_flat
);

    logic [$clog2(ADDRESS_NUMBER_A)-1:0] ada [BLOCK_COUNT-1:0];
    logic [BLOCK_DATA_WIDTH_A-1:0] din [BLOCK_COUNT-1:0];
    logic [$clog2(ADDRESS_NUMBER_B)-1:0] adb [BLOCK_COUNT-1:0];
    logic [BLOCK_DATA_WIDTH_B-1:0] dout [BLOCK_COUNT-1:0];

    // Connect Input Ports

    always_comb begin
        for (int i = 0; i < BLOCK_COUNT; i++) begin
            din[i] = I_din_flat[i*BLOCK_DATA_WIDTH_A +: BLOCK_DATA_WIDTH_A];
            ada[i] = I_ada_flat[i*$clog2(ADDRESS_NUMBER_A) +: $clog2(ADDRESS_NUMBER_A)];
            adb[i] = I_adb_flat[i*$clog2(ADDRESS_NUMBER_B) +: $clog2(ADDRESS_NUMBER_B)];
        end
    end




    genvar block;
    generate
        for(block = 0; block < BLOCK_COUNT; block++) begin : block_gen
           SDPB_Wrapper #(
                .ADDRESS_DEPTH_A(ADDRESS_NUMBER_A),
                .DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
                .ADDRESS_DEPTH_B(ADDRESS_NUMBER_B),
                .DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
            ) sdpb_inst (
                .clka(I_clka),
                .cea(I_cea),
                .oce(I_oce),
                .reseta(I_reseta),
                .ada(ada[block]),
                .din(din[block]),

                .clkb(I_clkb),
                .ceb(I_ceb),
                .resetb(I_resetb),
                .adb(adb[block]),
                .dout(dout[block])
            );
        end
    endgenerate

    // Connect Output Ports
    always_comb begin
        for (int i = 0; i < BLOCK_COUNT; i++) begin
            O_dout_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B] = dout[i];
        end
    end

endmodule