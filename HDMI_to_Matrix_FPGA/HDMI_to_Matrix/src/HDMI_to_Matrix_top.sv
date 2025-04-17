
// Raspberry Pi custom Resolution: https://stackoverflow.com/questions/52335356/custom-resolution-on-raspberry-pi


module LED_Matrix_top #(
    parameter CHANNEL_NUMBER = 3,
    parameter BYTES_PER_MATRIX = 8*16*3,
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

    // =================== Parameters ===================
    localparam SPI_SIZE = 24; // Size of the SPI data
    localparam COLOR_COUNT = 3; // Number of colors (RGB)
    localparam BATCH_SIZE = 8; // Number of pixels per batch

    //=================== Internal Signals ===================
    // DVI_RX Module Signals
    logic [3:0] pll_phase;
    logic pll_phase_lock;
    logic rgb_clk;
    logic rgb_vs;
    logic rgb_hs;
    logic rgb_de;
    logic [7:0] rgb_color [COLOR_COUNT-1:0]; // RGB color data


    DVI_RX_Wrapper #(
        .SIMULATION(0),                 // set to 1 for simulation, 0 for real hardware
        .H_ACTIVE(128),                 // oder tatsächliche Werte für dein Testbild
        .H_TOTAL(144),
        .V_ACTIVE(32),
        .V_TOTAL(40)
    ) DVI_RX_inst (
        .I_rst_n(btn[0]),
        .I_tmds_clk_p(I_tmds_clk_p),
        .I_tmds_clk_n(I_tmds_clk_n),
        .I_tmds_data_p(I_tmds_data_p),
        .I_tmds_data_n(I_tmds_data_n),
        .clk(clk),                      // only relevant for simulation

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



    // signals for next stage
    logic [COLOR_COUNT-1:0] batch_ready; // Batch ready signals for each color channel
    logic [8*BATCH_SIZE-1:0] batches [COLOR_COUNT-1:0]; // Batches of pixel data for each color channel

    genvar color;
    generate
        for (color = 0; color < COLOR_COUNT; color++) begin : color_batch
            // Instantiate the Color Batch Buffer for each color channel
            Color_Batch_Buffer #(
                .BATCH_SIZE(BATCH_SIZE)
            ) color_buffer_inst (
                .I_rgb_clk(rgb_clk),
                .I_rst_n(btn[0]),
                .I_color(rgb_color[color]),
                .I_color_valid(rgb_de),
                .O_batch_ready(batch_ready[color]),
                .O_batch_color(batches[color])
            );
        end
    endgenerate





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

endmodule




