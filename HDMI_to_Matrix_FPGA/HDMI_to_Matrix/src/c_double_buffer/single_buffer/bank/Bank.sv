module Bank #(
    parameter int ADDRESS_DEPTH = 512,
    parameter int BLOCK_DATA_WIDTH = 32,
    parameter int BLOCK_COUNT = 4,
    parameter int BANDWIDTH = BLOCK_COUNT * BLOCK_DATA_WIDTH
)(
    input  logic                        clka,
    input  logic                        cea,
    input  logic                        oce,
    input  logic                        reseta,
    input  logic [$clog2(ADDRESS_DEPTH)-1:0] ada,
    input  logic [BANDWIDTH-1:0]       din,

    input  logic                        clkb,
    input  logic                        ceb,
    input  logic                        resetb,
    input  logic [$clog2(ADDRESS_DEPTH)-1:0] adb,
    output logic [BANDWIDTH-1:0]       dout
);

    // Signals
    logic [BLOCK_DATA_WIDTH-1:0] block_data_in [BLOCK_COUNT-1:0]; // Data input for each block
    logic [BLOCK_DATA_WIDTH-1:0] block_data_out [BLOCK_COUNT-1:0]; // Data output for each block


    // Distribute the input data to each block
    always_comb begin
        for (int i = 0; i < BLOCK_COUNT; i++) begin
            block_data_in[i] = din[i*BLOCK_DATA_WIDTH +: BLOCK_DATA_WIDTH];
        end
    end



    genvar block;
    generate
        for(block = 0; block < BLOCK_COUNT; block++) begin : block_gen
           SDPB_Wrapper #(
                .ADDRESS_DEPTH_A(ADDRESS_DEPTH),
                .DATA_WIDTH_A(BLOCK_DATA_WIDTH),
                .ADDRESS_DEPTH_B(ADDRESS_DEPTH),
                .DATA_WIDTH_B(BLOCK_DATA_WIDTH)
            ) sdpb_inst (
                .clka(clka),
                .cea(cea),
                .oce(oce),
                .reseta(reseta),
                .ada(ada),
                .din(block_data_in[block]),

                .clkb(clkb),
                .ceb(ceb),
                .resetb(resetb),
                .adb(adb),
                .dout(block_data_out[block])
            );
        end
    endgenerate

    // Collects the output data from each block
    always_comb begin
        for (int i = 0; i < BLOCK_COUNT; i++) begin
            dout[i*BLOCK_DATA_WIDTH +: BLOCK_DATA_WIDTH] = block_data_out[i];
        end
    end

endmodule