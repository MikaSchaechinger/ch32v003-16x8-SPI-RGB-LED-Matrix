
// Raspberry Pi custom Resolution: https://stackoverflow.com/questions/52335356/custom-resolution-on-raspberry-pi


module LED_Matrix_top #(
    parameter CHANNEL_NUMBER = 3,
    parameter BYTES_PER_MATRIX = 8*16*3,
    parameter BATCH_SIZE = 16,
    parameter DIV_FACTOR = 1000 // Slow Clock Divider
)(
    input wire clk,
    input wire [1:0] btn,

    input wire I_tmds_clk_p,
    input wire I_tmds_clk_n,
    input wire [2:0] I_tmds_data_p,
    input wire [2:0] I_tmds_data_n,

    output wire spi_clk,
    output wire [CHANNEL_NUMBER-1:0] spi_mosi,
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
    logic [7:0] rgb_color [CHANNEL_NUMBER-1:0];

    DVI_RX_Wrapper #(
        .SIMULATION(0),
        .H_ACTIVE(128),
        .H_TOTAL(144),
        .V_ACTIVE(32),
        .V_TOTAL(40)
    ) DVI_RX_inst (
        .I_rst_n(btn[0]),
        .I_tmds_clk_p(I_tmds_clk_p),
        .I_tmds_clk_n(I_tmds_clk_n),
        .I_tmds_data_p(I_tmds_data_p),
        .I_tmds_data_n(I_tmds_data_n),
        .clk(clk),

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

    // ========== Input Logic (ehemals mehrere Einzelmodule) ==========
    logic [8*BATCH_SIZE-1:0] data_distributed [CHANNEL_NUMBER-1:0];
    logic [$clog2(BATCH_SIZE)-1:0] address_distributed [CHANNEL_NUMBER-1:0];
    logic clk_distributed;

    logic [$clog2(1920)-1:0] image_width;
    logic [$clog2(1080)-1:0] image_height;
    logic image_valid;

    Input_Logic #(
        .COLOR_COUNT(CHANNEL_NUMBER),
        .BATCH_SIZE(BATCH_SIZE),
        .MAX_WIDTH(1920),
        .MAX_HEIGHT(1080)
    ) input_logic_inst (
        .rst_n(btn[0]),
        .rgb_clk(rgb_clk),
        .rgb_de(rgb_de),
        .rgb_hs(rgb_hs),
        .rgb_vs(rgb_vs),
        .rgb_color(rgb_color),

        .data_distributed(data_distributed),
        .address_distributed(address_distributed),
        .clk_distributed(clk_distributed),

        .image_width(image_width),
        .image_height(image_height),
        .image_valid(image_valid)
    );

    // ========== Double Buffer ==========
    Double_Buffer #(
        .ADDRESS_DEPTH(480),
        .BANK_COUNT(CHANNEL_NUMBER),
        .BLOCK_COUNT(4),
        .BLOCK_DATA_WIDTH(32)
    ) double_buffer_inst (
        .rst_n(btn[0]),
        .clka(rgb_clk),
        .clk_data_in(clk_distributed),
        .ada(address_distributed),
        .din(data_distributed),

        .clkb(clk),
        .clk_data_out(),
        .adb(),
        .dout_flat(),

        .swap_trigger(),
        .data_valid()
    );

endmodule






    /*
    // Output Module Signals
    logic [SPI_SIZE-1:0] data_in [CHANNEL_NUMBER-1:0];

    Output_Module out#(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .SPI_SIZE(SPI_SIZE),
        .MSB_FIRST(1)
    )(
        .clk(),
        .rst(~btn[0]),
        .data_in()
        .new_image(),
        .new_column(),
        .next_data(),
        .extra_bit(),
        .tx_finish(),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .ser_clk(shift_clk),
        .ser_data(shift_ser),
        .ser_stcp(shift_stcp),
        .ser_n_enable(shift_en)
    );
    */
//endmodule




