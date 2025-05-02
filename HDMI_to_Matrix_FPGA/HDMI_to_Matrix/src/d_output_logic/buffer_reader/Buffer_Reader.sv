module Buffer_Reader #(
    parameter int BLOCK_WIDTH = 32,
    parameter int BLOCK_DEPTH = 480,
    parameter int BANK_COUNT = 3,
    parameter int BLOCK_COUNT = 4,
    parameter int SPI_CHANNEL_COUNT = 3
) (
    input  logic                            I_rst_n,
    input  logic                            I_clk,

    input  logic                            I_read_next // Trigger to read next data

    // output logic 
);






endmodule