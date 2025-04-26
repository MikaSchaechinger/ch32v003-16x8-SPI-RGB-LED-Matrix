module Single_Buffer #(
    parameter int ADDRESS_DEPTH = 512,
    parameter int BANK_COUNT = 3,
    parameter int BLOCK_COUNT = 4,
    parameter int BLOCK_DATA_WIDTH = 32,
    parameter int BANDWIDTH = BLOCK_COUNT * BLOCK_DATA_WIDTH
)(
    input  logic                         clka,
    input  logic                         cea,
    input  logic                         oce,
    input  logic                         reseta,
    input  logic [$clog2(ADDRESS_DEPTH)-1:0] ada [BANK_COUNT-1:0],
    input  logic [BANDWIDTH-1:0]       din [BANK_COUNT-1:0],

    input  logic                         clkb,
    input  logic                         ceb,
    input  logic                         resetb,
    input  logic [$clog2(ADDRESS_DEPTH)-1:0] adb [BANK_COUNT-1:0],
    output logic [BANDWIDTH*BANK_COUNT-1:0]  dout_flat
);

    logic [BANDWIDTH-1:0] internal_dout [BANK_COUNT-1:0];

    genvar bank;
    generate 
        for (bank = 0; bank < BANK_COUNT; bank++) begin : bank_gen
            Bank #(
                .ADDRESS_DEPTH(ADDRESS_DEPTH),
                .BLOCK_DATA_WIDTH(BLOCK_DATA_WIDTH),
                .BLOCK_COUNT(BLOCK_COUNT)
            ) bank_inst (
                .clka(clka),
                .cea(cea),
                .oce(oce),
                .reseta(reseta),
                .ada(ada[bank]),
                .din(din[bank]),

                .clkb(clkb),
                .ceb(ceb),
                .resetb(resetb),
                .adb(adb[bank]),
                .dout(internal_dout[bank])
            );
        end
    endgenerate

    always_comb begin
        for (int i = 0; i < BANK_COUNT; i++) begin
            dout_flat[i*BANDWIDTH +: BANDWIDTH] = internal_dout[i];
        end
    end
    

endmodule