    // DVI_RX_Wrapper: Umschaltmodul zwischen realem DVI_RX-IP und DVI_RX_SIM für Simulation

    module DVI_RX_Wrapper #(
        parameter int H_ACTIVE = 128,
        parameter int H_TOTAL  = 144,
        parameter int V_ACTIVE = 32,
        parameter int V_TOTAL  = 40
    )(
        input  logic        I_rst_n,
        input  logic        I_tmds_clk_p,
        input  logic        I_tmds_clk_n,
        input  logic [2:0]  I_tmds_data_p,
        input  logic [2:0]  I_tmds_data_n,
        input  logic        clk,       // Nur für SIM-Modell erforderlich

        output logic [3:0]  O_pll_phase,
        output logic        O_pll_phase_lock,
        output logic        O_rgb_clk,
        output logic        O_rgb_vs,
        output logic        O_rgb_hs,
        output logic        O_rgb_de,
        output logic [7:0]  O_rgb_r,
        output logic [7:0]  O_rgb_g,
        output logic [7:0]  O_rgb_b
    );

    `ifndef REAL
        `define SIMULATION 0
    `endif 

    `ifdef SIMULATION  // Simulation aktivieren
        
        DVI_RX_SIM #(
            .H_ACTIVE(H_ACTIVE),
            .H_TOTAL(H_TOTAL),
            .V_ACTIVE(V_ACTIVE),
            .V_TOTAL(V_TOTAL)
        ) dvi_sim_inst (
            .clk(clk),
            .rst_n(I_rst_n),
            .O_pll_phase(O_pll_phase),
            .O_pll_phase_lock(O_pll_phase_lock),
            .O_rgb_clk(O_rgb_clk),
            .O_rgb_vs(O_rgb_vs),
            .O_rgb_hs(O_rgb_hs),
            .O_rgb_de(O_rgb_de),
            .O_rgb_r(O_rgb_r),
            .O_rgb_g(O_rgb_g),
            .O_rgb_b(O_rgb_b)
        );
        
    `else  // Simulation deaktivieren
        
        DVI_RX dvi_real_inst (
            .I_rst_n(I_rst_n),
            .I_tmds_clk_p(I_tmds_clk_p),
            .I_tmds_clk_n(I_tmds_clk_n),
            .I_tmds_data_p(I_tmds_data_p),
            .I_tmds_data_n(I_tmds_data_n),
            .O_pll_phase(O_pll_phase),
            .O_pll_phase_lock(O_pll_phase_lock),
            .O_rgb_clk(O_rgb_clk),
            .O_rgb_vs(O_rgb_vs),
            .O_rgb_hs(O_rgb_hs),
            .O_rgb_de(O_rgb_de),
            .O_rgb_r(O_rgb_r),
            .O_rgb_g(O_rgb_g),
            .O_rgb_b(O_rgb_b)
        );
    `endif


    endmodule