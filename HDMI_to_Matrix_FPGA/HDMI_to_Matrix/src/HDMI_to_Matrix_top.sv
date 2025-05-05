
module HDMI_to_Matrix_top #(    
    // HDMI Configuration
    parameter HDMI_MAX_WIDTH = 1920,
    parameter HDMI_MAX_HEIGHT = 1080,
    parameter COLOR_COUNT = 3,

    // Input Configuration
    parameter BATCH_SIZE = 16,
    // RAM Configuration
    parameter BYTES_PER_BLOCK = 2250,
    parameter BANK_COUNT = 6,
    parameter BLOCK_COUNT = 2,
    parameter BLOCK_DATA_WIDTH_A = 32, // Write Port
    parameter BLOCK_DATA_WIDTH_B = 8,  // Read Port
    parameter ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A, // Write Port
    parameter ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B, // Read Port

    // SPI Configuration
    parameter SPI_CHANNEL_NUMBER = 24
)(
    input wire sys_clk_27MHz,
    input wire [1:0] btn,

    input wire I_tmds_clk_p,
    input wire I_tmds_clk_n,
    input wire [2:0] I_tmds_data_p,
    input wire [2:0] I_tmds_data_n,

    output wire spi_clk,
    output wire [SPI_CHANNEL_NUMBER-1:0] spi_mosi,
    output wire shift_clk,
    output wire shift_ser,
    output wire shift_stcp,
    output wire shift_en,
    output reg [5:0] led
);

    // Some parameters must have the right proportion to work correctly
    // They must be checked. If they are not correct, an error message will be shown.
    localparam int BATCH_DATA_TOTAL_WIDTH = BLOCK_DATA_WIDTH_A * BLOCK_COUNT * BANK_COUNT;
    localparam int BUFFER_WRITE_TOTAL_WIDTH = 8 * BATCH_SIZE * COLOR_COUNT;
    localparam int BUFFER_READ_TOTAL_WIDTH = BLOCK_DATA_WIDTH_B * BLOCK_COUNT * BANK_COUNT;
    initial begin
        if (BLOCK_DATA_WIDTH_A > BLOCK_DATA_WIDTH_B) begin
            if (BLOCK_DATA_WIDTH_A % BLOCK_DATA_WIDTH_B != 0) begin
                $error("BLOCK_DATA_WIDTH_A must be a multiple of BLOCK_DATA_WIDTH_B.");
                $finish;
            end
        end else if (BLOCK_DATA_WIDTH_B > BLOCK_DATA_WIDTH_A) begin
            if (BLOCK_DATA_WIDTH_B % BLOCK_DATA_WIDTH_A != 0) begin
                $error("BLOCK_DATA_WIDTH_B must be a multiple of BLOCK_DATA_WIDTH_A.");
                $finish;
            end
        end
        if (BATCH_DATA_TOTAL_WIDTH != BUFFER_WRITE_TOTAL_WIDTH) begin
            // Error message with the values of the parameters
            $error("BATCH_DATA_TOTAL_WIDTH (%0d) must be equal to BUFFER_WRITE_TOTAL_WIDTH (%0d).", BATCH_DATA_TOTAL_WIDTH, BUFFER_WRITE_TOTAL_WIDTH);
            $finish;
        end

        if (BUFFER_WRITE_TOTAL_WIDTH % BUFFER_READ_TOTAL_WIDTH != 0) begin
            // Error message with the values of the parameters
            $error("BUFFER_WRITE_TOTAL_WIDTH (%0d) must be a multiple of BUFFER_READ_TOTAL_WIDTH (%0d).", BUFFER_WRITE_TOTAL_WIDTH, BUFFER_READ_TOTAL_WIDTH);
            $finish;
        end
    end




    // ========== HDMI Input ==========
    logic [3:0] pll_phase;
    logic pll_phase_lock;
    logic rgb_clk;
    logic rgb_vs;
    logic rgb_hs;
    logic rgb_de;
    logic [7:0] rgb_color [COLOR_COUNT-1:0];

    DVI_RX_Wrapper #(
        .H_ACTIVE(640),  // Parameters are only for simulation
        .H_BLANK(16),   // min 16
        .V_ACTIVE(6),
        .V_BLANK(4)     // min 4
    ) DVI_RX_inst (
        .I_rst_n(btn[0]),
        .I_tmds_clk_p(I_tmds_clk_p),
        .I_tmds_clk_n(I_tmds_clk_n),
        .I_tmds_data_p(I_tmds_data_p),
        .I_tmds_data_n(I_tmds_data_n),
        .I_clk(sys_clk_27MHz),

        .O_pll_phase(pll_phase),
        .O_pll_phase_lock(pll_phase_lock),
        .O_rgb_clk(rgb_clk),
        .O_rgb_vs(rgb_vs),
        .O_rgb_hs(rgb_hs),
        .O_rgb_de(rgb_de),
        .O_rgb_r(rgb_color[0]),
        .O_rgb_g(rgb_color[1]),
        .O_rgb_b(rgb_color[2])
    );

    // ========== Input Logic ==========
    logic [8*BATCH_SIZE*COLOR_COUNT-1:0] batch_data_flat;
    logic [$clog2(ADDRESS_NUMBER_A)-1:0] write_address;
    logic write_enable;

    logic [$clog2(HDMI_MAX_WIDTH)-1:0] image_width_in_side;
    logic [$clog2(HDMI_MAX_HEIGHT)-1:0] image_height_in_side;
    logic image_valid_in_side;
    logic swap_trigger;
    logic hs_detected_in_side, vs_detected_in_side;
    logic hs_detected_out_side, vs_detected_out_side;

    Input_Logic #(
        .MAX_WIDTH(HDMI_MAX_WIDTH),
        .MAX_HEIGHT(HDMI_MAX_HEIGHT),
        .CHANNEL_COUNT(COLOR_COUNT),
        .BATCH_SIZE(BATCH_SIZE),
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A)
    ) input_logic_inst (
        .I_rst_n(btn[0]),
        .I_rgb_clk(rgb_clk),
        .I_rgb_de(rgb_de),
        .I_rgb_hs(rgb_hs),
        .I_rgb_vs(rgb_vs),
        .I_rgb_color(rgb_color),

        .O_data_flat(batch_data_flat),
        .O_address(write_address),
        .O_write_enable(write_enable),

        .O_image_width(image_width_in_side),
        .O_image_height(image_height_in_side),
        .O_image_valid(image_valid_in_side),

        .O_batch_ready(),

        .O_swap_trigger(swap_trigger),
        .O_hs_detected(hs_detected_in_side),
        .O_vs_detected(vs_detected_in_side)
    );

    // ========== Double Buffer ==========

    logic read_enable;
    logic [$clog2(ADDRESS_NUMBER_B)-1:0] read_address;
    logic [COLOR_COUNT*BLOCK_DATA_WIDTH_B*BLOCK_COUNT-1:0] dout_flat;
    logic buffer_data_valid;

    logic [$clog2(HDMI_MAX_HEIGHT)-1:0] image_width_out_side;
    logic [$clog2(HDMI_MAX_HEIGHT)-1:0] image_height_out_side;
    logic image_valid_out_side;

    logic start_line_out;

    Matrix_Buffer #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .MAX_WIDTH(HDMI_MAX_WIDTH),
        .MAX_HEIGHT(HDMI_MAX_HEIGHT),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) buffer_inst (
        .I_rst_n(btn[0]),
        .I_swap_trigger(swap_trigger),
        // Input Side
        .I_clka(rgb_clk),
        .I_write_enable(write_enable),
        .I_write_address(write_address),
        .I_data_flat(batch_data_flat),
        
        .I_image_width(image_width_in_side),
        .I_image_height(image_height_in_side),
        .I_image_valid(image_valid_in_side),
        .I_hs_detected(hs_detected_in_side),
        .I_vs_detected(vs_detected_in_side),
        // Output Side
        .I_clkb(sys_clk_27MHz),
        .I_read_enable(read_enable),
        .I_read_address(read_address),
        .O_data_flat(dout_flat),

        .O_image_width(image_width_out_side),
        .O_image_height(image_height_out_side),
        .O_image_valid(image_valid_out_side),
        .O_hs_detected(hs_detected_out_side),
        .O_vs_detected(vs_detected_out_side),

        .O_data_valid(buffer_data_valid),

        .O_buffer_updated(start_line_out)
    );


    // ========== Output Logic ==========
    logic [BLOCK_DATA_WIDTH_B-1:0] data_out [SPI_CHANNEL_NUMBER-1:0];
    logic next_image, next_column, next_data, tx_finish;
    logic [SPI_CHANNEL_NUMBER*BLOCK_DATA_WIDTH_B-1:0] spi_data_flat;

    Output_Logic #(
        .SPI_CHANNEL_NUMBER(SPI_CHANNEL_NUMBER),
        .MAX_WIDTH(HDMI_MAX_WIDTH),
        .MAX_HEIGHT(HDMI_MAX_HEIGHT),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) output_logic_inst (
        .I_clk(sys_clk_27MHz),
        .I_rst_n(btn[0]),
        // Communication with Matrix_Buffer
        .I_image_width(image_width_in_side),
        .I_start_line_out(start_line_out),
        .I_hs_detected(hs_detected_out_side),
        .I_vs_detected(vs_detected_out_side),
        .I_image_height(image_height_in_side),
        .I_image_valid(image_valid_in_side),

        .I_data_valid(buffer_data_valid),
        .O_read_enable(read_enable),
        .O_read_address(read_address),
        .I_data_flat(dout_flat),
        // Communication with Output_Module
        .I_tx_finish(tx_finish),
        .O_next_data(next_data),
        .O_next_column(next_column),
        .O_next_image(next_image),
        .O_data_flat(spi_data_flat)
    );

    // ========== Output Module ==========
    Output_Module #(
        .CHANNEL_NUMBER(SPI_CHANNEL_NUMBER),
        .SPI_SIZE(BLOCK_DATA_WIDTH_B),
        .MSB_FIRST(1)
    ) output_module_inst (
        .I_clk(sys_clk_27MHz),
        .I_rst_n(btn[0]),
        .I_data_flat(spi_data_flat),
        .I_next_image(next_image),
        .I_next_column(next_column),
        .I_next_data(next_data),
        .I_extra_bit(1'b1),
        .O_tx_finish(tx_finish),
        .O_spi_clk(spi_clk),
        .O_spi_mosi(spi_mosi),
        .O_ser_clk(shift_clk),
        .O_ser_data(shift_ser),
        .O_ser_stcp(shift_stcp),
        .O_ser_n_enable(shift_en)
    );

endmodule
