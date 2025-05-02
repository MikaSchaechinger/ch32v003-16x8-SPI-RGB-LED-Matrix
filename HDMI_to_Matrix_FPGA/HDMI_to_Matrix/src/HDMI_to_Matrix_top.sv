// Raspberry Pi custom Resolution: https://stackoverflow.com/questions/52335356/custom-resolution-on-raspberry-pi

module LED_Matrix_top #(    
    // HDMI Configuration
    parameter HDMI_MAX_WIDTH = 1920,
    parameter HDMI_MAX_HEIGHT = 1080,
    parameter COLOR_COUNT = 3,

    // Input Configuration
    parameter BATCH_SIZE = 4,

    // RAM Configuration
    parameter BYTES_PER_BLOCK = 2250,
    parameter BANK_COUNT = 6,
    parameter BLOCK_COUNT = 2,
    parameter BLOCK_DATA_WIDTH_A = 32, // Write Port
    parameter BLOCK_DATA_WIDTH_B = 8,  // Read Port

    // SPI Configuration
    parameter SPI_CHANNEL_NUMBER = 8
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

    // ========== HDMI Input ==========
    logic [3:0] pll_phase;
    logic pll_phase_lock;
    logic rgb_clk;
    logic rgb_vs;
    logic rgb_hs;
    logic rgb_de;
    logic [7:0] rgb_color [COLOR_COUNT-1:0];

    DVI_RX_Wrapper #(
        .SIMULATION(0), 
        .H_ACTIVE(128), // Parameters are only for simulation
        .H_TOTAL(144),
        .V_ACTIVE(32),
        .V_TOTAL(40)
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
    logic [8*BATCH_SIZE*CHANNEL_NUMBER-1:0] batch_data_flat;
    logic [$clog2(BLOCK_DATA_WIDTH_A)-1:0] write_address;
    logic write_enable;

    logic [$clog2(HDMI_MAX_WIDTH)-1:0] image_width;
    logic [$clog2(HDMI_MAX_HEIGHT)-1:0] image_height;
    logic image_valid;

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

        .O_image_width(image_width),
        .O_image_height(image_height),
        .O_image_valid(image_valid)
    );

    // ========== Double Buffer ==========
    logic swap_trigger;

    logic read_enable;
    logic [$clog2(BLOCK_DATA_WIDTH_B)-1:0] read_address;
    logic [CHANNEL_NUMBER*BLOCK_DATA_WIDTH_B*BLOCK_COUNT-1:0] dout_flat;
    logic data_valid;

    Matrix_Buffer #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) buffer_inst (
        .I_rst_n(btn[0]),
        .I_swap_trigger(swap_trigger),

        .I_clka(rgb_clk),
        .I_write_enable(write_enable),
        .I_write_address(write_address),
        .I_data_flat(batch_data_flat),

        .I_clkb(sys_clk_27MHz),
        .I_read_enable(read_enable),
        .I_read_address(read_address),
        .O_data_flat(dout_flat),

        .O_data_valid(data_valid)
    );


    // ========== Output Logic ==========
    logic [BLOCK_DATA_WIDTH_B-1:0] data_out [SPI_CHANNEL_NUMBER-1:0];
    logic next_image, next_column, next_data, tx_finish;

    Output_Logic #(
        .SPI_CHANNEL_NUMBER(SPI_CHANNEL_NUMBER),
        .MAX_WIDTH(HDMI_MAX_WIDTH),
        .MAX_HEIGHT(HDMI_MAX_HEIGHT),
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) output_logic_inst (
        .I_clk(sys_clk_27MHz),
        .I_rst_n(btn[0]),
        // Communication with Input_Logic
        .I_image_width(image_width),
        .I_image_height(image_height),
        .I_image_valid(image_valid),
        // Communication with Matrix_Buffer
        .I_data_valid(data_valid),
        .O_read_enable(read_enable),
        .O_read_address(read_address),
        .I_data_flat(dout_flat),
        // Communication with Output_Module
        .I_tx_finish(tx_finish),
        .O_next_data(next_data),
        .O_next_column(next_column),
        .O_next_image(next_image),
        .O_data_out(data_out)
    );

    // ========== Output Module ==========
    Output_Module #(
        .CHANNEL_NUMBER(SPI_CHANNEL_NUMBER),
        .SPI_SIZE(BLOCK_DATA_WIDTH_B),
        .MSB_FIRST(1)
    ) output_module_inst (
        .I_clk(sys_clk_27MHz),
        .I_rst_n(btn[0]),
        .I_data_in(data_out),
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
