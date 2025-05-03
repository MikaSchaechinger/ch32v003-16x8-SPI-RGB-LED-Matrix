module Matrix_Buffer #(
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int MAX_WIDTH = 1920,
    parameter int MAX_HEIGHT = 1080,
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

    input  logic [$clog2(MAX_WIDTH)-1:0] I_image_width,
    input  logic [$clog2(MAX_HEIGHT)-1:0] I_image_height,
    input  logic                        I_image_valid,
    input  logic                        I_next_column,
    input  logic                        I_next_image,

    // Output Side
    input  logic                         I_clkb,
    input  logic                         I_read_enable,
    input  logic [$clog2(ADDRESS_NUMBER_B)-1:0] I_read_address,
    output logic [(BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_B-1:0] O_data_flat,

    output logic [$clog2(MAX_WIDTH)-1:0] O_image_width,
    output logic [$clog2(MAX_HEIGHT)-1:0] O_image_height,
    output logic                        O_image_valid,
    output logic                        O_next_column,
    output logic                        O_next_image,
    
    output logic                        O_data_valid,     
    
    output logic                        O_buffer_updated           // High for one clkb after swap_trigger
);

    // Synchronisation und Puls-Erzeugung für O_buffer_updated
    logic swap_trigger_sync_0, swap_trigger_sync_1, swap_trigger_sync_2;

    always_ff @(posedge I_clkb or negedge I_rst_n) begin
        if (!I_rst_n) begin
            swap_trigger_sync_0 <= 0;   // For synchronisation
            swap_trigger_sync_1 <= 0;   // For synchronisation
            swap_trigger_sync_2 <= 0;   // For edge detection
        end else begin
            swap_trigger_sync_0 <= I_swap_trigger;
            swap_trigger_sync_1 <= swap_trigger_sync_0;
            swap_trigger_sync_2 <= swap_trigger_sync_1;
        end
    end

    wire rising_edge_swap_trigger = swap_trigger_sync_1 & ~swap_trigger_sync_2;

    always_ff @(posedge I_clkb or negedge I_rst_n) begin
        if (!I_rst_n)
            O_buffer_updated <= 1'b0;
        else
            O_buffer_updated <= rising_edge_swap_trigger;
    end



    // Info Buffer buffers extra information from the image to the output side
    Info_Buffer #(
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_HEIGHT(MAX_HEIGHT)
    ) info_buffer_inst (
        .I_rst_n(I_rst_n),
        .I_clk(I_clka),
        .I_swap_trigger(I_swap_trigger),

        .I_image_width(I_image_width),
        .I_image_height(I_image_height),
        .I_image_valid(I_image_valid),
        .I_next_column(I_next_column),
        .I_next_image(I_next_image),

        .O_image_width(O_image_width),
        .O_image_height(O_image_height),
        .O_image_valid(O_image_valid),
        .O_next_column(O_next_column),
        .O_next_image(O_next_image)
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