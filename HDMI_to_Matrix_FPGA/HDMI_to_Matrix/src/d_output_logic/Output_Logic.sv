module Output_Logic #(
    parameter int SPI_CHANNEL_NUMBER = 4,
    parameter int MAX_WIDTH = 1920,
    parameter int MAX_HEIGHT = 1080,

    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BLOCK_DATA_WIDTH_B = 8,  // Read Port
    parameter int ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B // Read Port
) (
    input  logic                         I_clk,
    input  logic                         I_rst_n,
    // Communication with Input_Logic
    input  logic [$clog2(MAX_WIDTH)-1:0]    I_image_width,
    input  logic [$clog2(MAX_HEIGHT)-1:0]   I_image_height,
    input  logic                         I_image_valid,
    // Communication with Matrix_Buffer
    input  logic                         I_data_valid,
    output logic                         O_read_enable,
    output logic [$clog2(ADDRESS_NUMBER_B)-1:0] O_read_address,
    input logic [SPI_CHANNEL_NUMBER*BLOCK_DATA_WIDTH_B-1:0] I_data_flat,
    // Communication with Output_Module
    input  logic                         I_tx_finish,
    output logic                         O_next_data,
    output logic                         O_next_column,
    output logic                         O_next_image,
    output logic [BLOCK_DATA_WIDTH_B-1:0] O_data_out [SPI_CHANNEL_NUMBER-1:0]
);




endmodule