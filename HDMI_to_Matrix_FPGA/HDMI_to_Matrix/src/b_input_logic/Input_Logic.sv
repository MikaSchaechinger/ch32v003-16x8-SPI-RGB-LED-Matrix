module Input_Logic #(
    parameter CHANNEL_COUNT = 3,
    parameter BATCH_SIZE = 16,
    parameter BLOCK_WIDTH = 32,
    parameter BLOCK_DEPTH = 480,
    parameter MAX_WIDTH = 1920,
    parameter MAX_HEIGHT = 1080
)(
    input  logic                            rst_n,
    input  logic                            rgb_clk,
    input  logic                            rgb_de,
    input  logic                            rgb_hs,
    input  logic                            rgb_vs,
    input  logic [7:0]                      rgb_color [0:CHANNEL_COUNT-1],

    output logic [8*BATCH_SIZE-1:0]         data_distributed [0:CHANNEL_COUNT-1],
    output logic [$clog2(BLOCK_DEPTH)-1:0]   address_distributed [0:CHANNEL_COUNT-1],
    output logic                            clk_distributed,

    output logic [$clog2(MAX_WIDTH)-1:0]    image_width,
    output logic [$clog2(MAX_HEIGHT)-1:0]   image_height,
    output logic                            image_valid
);
    localparam int INTERN_ADDRESS_BITS = $clog2(BATCH_SIZE*CHANNEL_COUNT);
    localparam int OUT_ADDRESS_BITS = $clog2(BATCH_SIZE);

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
                .I_rgb_clk(rgb_clk),
                .I_rst_n(rst_n),
                .I_color(rgb_color[color]),
                .I_color_valid(rgb_de),
                .O_batch_ready(batch_ready[color]),
                .O_batch_clk_out(batch_ready_clk[color]),
                .O_batch_color(batches[color])
            );
        end
    endgenerate

    // Sync Manager
    logic image_width_valid, image_height_valid;
    logic new_row, new_frame;

    Sync_Manager #(
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_HEIGHT(MAX_HEIGHT),
        .DELAY(BATCH_SIZE)
    ) sync_manager_inst (
        .I_rst_n(rst_n),
        .I_rgb_clk(rgb_clk),
        .I_rgb_de(rgb_de),
        .I_rgb_vs(rgb_vs),
        .I_rgb_hs(rgb_hs),
        .O_image_width(image_width),
        .O_image_height(image_height),
        .O_width_valid(image_width_valid),
        .O_height_valid(image_height_valid),
        .O_new_row(new_row),
        .O_new_frame(new_frame)
    );

    assign image_valid = image_width_valid & image_height_valid;

    // Address Generator
    logic [INTERN_ADDRESS_BITS-1:0] write_address;

    Address_Generator #(
        .ADDRESS_BITS(INTERN_ADDRESS_BITS)
    ) addr_gen_inst (
        .I_rst_n(rst_n),
        .I_address_up(batch_ready[0]),
        .I_address_reset(new_row),
        .O_address(write_address)
    );

    // Bank Distributor
    Bank_Distributor #(
        .CHANNEL_NUMBER(CHANNEL_COUNT),
        .CHANNEL_BANDWIDTH(8*BATCH_SIZE),
        .BLOCK_DEPTH(BLOCK_DEPTH), // fix oder parameterisierbar
        .I_ADDRESS_IN_BITS(INTERN_ADDRESS_BITS)
    ) bank_dist_inst (
        .I_clk_in(batch_ready_clk[0]),
        .I_data_in(batches),
        .I_address_in(write_address),
        .O_data_out(data_distributed),
        .O_address_out(address_distributed),
        .O_clk_out(clk_distributed)
    );

endmodule
