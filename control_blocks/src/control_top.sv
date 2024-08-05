module top(
    input wire clk,	// 27 MHz
    input wire [1:0] btn,
    
    input wire I_tmds_clk_p_i,
    input wire I_tmds_clk_n_i,
    input wire [2:0] I_tmds_data_p_i,
    input wire [2:0] I_tmds_data_n_i, 

    output wire slow_clk,
    output wire fast_clk,

	/*
    output wire O_rgb_clk_o,
    output wire O_rgb_vs_o,							// ????
    output wire O_rgb_hs_o,
    output wire O_rgb_de_o,
	*/
);


	// Clock generation of 250 MHz / 4 = 62.5 MHz
    Gowin_OSC Gowin_OSC_inst(
        .oscout(fast_clk) //output oscout
    );
	
	assign slow_clk = clk;


/*
	EDID_PROM EDID_PROM_inst(
		.I_clk(clk), //input I_clk
		.I_rst_n(1'b1), //input I_rst_n
		.I_scl(I_scl_i), //input I_scl
		.IO_sda(IO_sda_io) //inout IO_sda
	);
*/

/*
    spi_tx_n_mosi spi_tx_n_mosi_inst(
        .clk(),
        .rst(),
        .
    )
*/

	wire O_rgb_clk_o;
    wire O_rgb_vs_o;
    wire O_rgb_hs_o;
    wire O_rgb_de_o;

	wire [3:0] O_pll_phase_o;
	wire O_pll_phase_lock_o;
	wire [7:0] O_rgb_r_o;
	wire [7:0] O_rgb_g_o;
	wire [7:0] O_rgb_b_o;
    

	DVI_RX DVI_RX_inst(
		.I_rst_n(1'b1), //input I_rst_n
		.I_tmds_clk_p(I_tmds_clk_p_i), //input I_tmds_clk_p
		.I_tmds_clk_n(I_tmds_clk_n_i), //input I_tmds_clk_n
		.I_tmds_data_p(I_tmds_data_p_i), //input [2:0] I_tmds_data_p
		.I_tmds_data_n(I_tmds_data_n_i), //input [2:0] I_tmds_data_n

		.O_pll_phase(O_pll_phase_o), //output [3:0] O_pll_phase
		.O_pll_phase_lock(O_pll_phase_lock_o), //output O_pll_phase_lock
		.O_rgb_clk(O_rgb_clk_o), //output O_rgb_clk
		.O_rgb_vs(O_rgb_vs_o), //output O_rgb_vs
		.O_rgb_hs(O_rgb_hs_o), //output O_rgb_hs
		.O_rgb_de(O_rgb_de_o), //output O_rgb_de
		.O_rgb_r(O_rgb_r_o), //output [7:0] O_rgb_r
		.O_rgb_g(O_rgb_g_o), //output [7:0] O_rgb_g
		.O_rgb_b(O_rgb_b_o) //output [7:0] O_rgb_b
	);

endmodule