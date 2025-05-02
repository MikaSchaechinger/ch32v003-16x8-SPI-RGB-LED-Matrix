module Input_Logic #(
    // Configuration Parameters
    parameter int MAX_WIDTH = 1920,
    parameter int MAX_HEIGHT = 1080,
    // Input Parameters
    parameter int CHANNEL_COUNT = 3,
    parameter int BATCH_SIZE = 4,

    // Buffer Parameters
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BANK_COUNT = 6,
    parameter int BLOCK_COUNT = 2,
    parameter int BLOCK_DATA_WIDTH_A = 32,  // Write Port
    parameter int BANDWIDTH_A = BANK_COUNT * BLOCK_DATA_WIDTH_A, // Write Port
    parameter int ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A // Write Port
)(
    input  logic                            I_rst_n,
    input  logic                            I_rgb_clk,
    input  logic                            I_rgb_de,
    input  logic                            I_rgb_hs,
    input  logic                            I_rgb_vs,
    input  logic [7:0]                      I_rgb_color [CHANNEL_COUNT-1:0],

    output logic [8*BATCH_SIZE*CHANNEL_COUNT-1:0]   O_data_flat,
    output logic [$clog2(ADDRESS_NUMBER_A)-1:0]     O_address,
    output logic                            O_write_enable,

    output logic [$clog2(MAX_WIDTH)-1:0]    O_image_width,
    output logic [$clog2(MAX_HEIGHT)-1:0]   O_image_height,
    output logic                            O_image_valid
);

    logic [7:0] rgb_color_0, rgb_color_1, rgb_color_2;
    assign rgb_color_0 = I_rgb_color[0];
    assign rgb_color_1 = I_rgb_color[1];
    assign rgb_color_2 = I_rgb_color[2];

    // Internal signals
    logic [CHANNEL_COUNT-1:0] batch_ready;
    logic [CHANNEL_COUNT-1:0] batch_ready_clk;
    logic [8*BATCH_SIZE-1:0] batches [CHANNEL_COUNT-1:0];

    // Color Batch Buffer Instanzen
    genvar color;
    generate
        for (color = 0; color < CHANNEL_COUNT; color++) begin : color_batch
            Color_Batch_Buffer #(
                .BATCH_SIZE(BATCH_SIZE)
            ) color_buffer_inst (
                .I_rgb_clk(I_rgb_clk),
                .I_rst_n(I_rst_n),
                .I_color(I_rgb_color[color]),
                .I_color_valid(I_rgb_de),
                .O_batch_ready(batch_ready[color]),
                .O_batch_clk_out(batch_ready_clk[color]),
                .O_batch_color(batches[color])
            );
        end
    endgenerate

    // Batches get combined and written to the output
    always_comb begin
        O_data_flat = {batches[2], batches[1], batches[0]};
    end

    assign O_clk_distributed = batch_ready_clk[0];


    // Sync Manager
    logic image_width_valid, image_height_valid;
    logic new_row, new_frame;

    Sync_Manager #(
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_HEIGHT(MAX_HEIGHT),
        .DELAY(BATCH_SIZE)
    ) sync_manager_inst (
        .I_rst_n(I_rst_n),
        .I_rgb_clk(I_rgb_clk),
        .I_rgb_de(I_rgb_de),
        .I_rgb_vs(I_rgb_vs),
        .I_rgb_hs(I_rgb_hs),
        .O_image_width(O_image_width),
        .O_image_height(O_image_height),
        .O_width_valid(image_width_valid),
        .O_height_valid(image_height_valid),
        .O_new_row(new_row),
        .O_new_frame(new_frame)
    );

    assign O_image_valid = image_width_valid & image_height_valid;

    localparam ADDRESS_BITS = $clog2(ADDRESS_NUMBER_A);

    // Address Generator
    logic [ADDRESS_BITS-1:0] write_address;

    Address_Generator #(
        .ADDRESS_BITS(ADDRESS_BITS)
    ) addr_gen_inst (
        .I_rst_n(I_rst_n),
        .I_clk(I_rgb_clk),
        .I_address_up(batch_ready[0]),
        .I_address_reset(new_row),
        .O_address(O_address)
    );

    


endmodule
