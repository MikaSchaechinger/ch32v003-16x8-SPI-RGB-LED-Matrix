// SDPB_Wrapper: Umschaltbares BRAM-Modul für Simulation oder reale IP-Instanz

module SDPB_Wrapper #(
    parameter int ADDRESS_DEPTH_A = 512,
    parameter int DATA_WIDTH_A    = 32,
    parameter int ADDRESS_DEPTH_B = 512,
    parameter int DATA_WIDTH_B    = 32
)(
    input  logic                         clka,
    input  logic                         cea,
    input  logic                         oce,
    input  logic                         reseta,
    input  logic [$clog2(ADDRESS_DEPTH_A)-1:0] ada,
    input  logic [DATA_WIDTH_A-1:0]      din,

    input  logic                         clkb,
    input  logic                         ceb,
    input  logic                         resetb,
    input  logic [$clog2(ADDRESS_DEPTH_B)-1:0] adb,
    output logic [DATA_WIDTH_B-1:0]      dout
);

    `ifndef REAL
        `define SIMULATION 0
    `endif

    `ifdef SIMULATION  // Simulation aktivieren
        SDPB_sim #(
            .ADDRESS_DEPTH_A(ADDRESS_DEPTH_A),
            .DATA_WIDTH_A(DATA_WIDTH_A),
            .ADDRESS_DEPTH_B(ADDRESS_DEPTH_B),
            .DATA_WIDTH_B(DATA_WIDTH_B)
        ) sim_inst (
            .clka(clka),
            .cea(cea),
            .oce(oce),
            .reseta(reseta),
            .ada(ada),
            .din(din),

            .clkb(clkb),
            .ceb(ceb),
            .resetb(resetb),
            .adb(adb),
            .dout(dout)
        );
    `else  // Simulation deaktivieren
        Gowin_SDPB real_inst (
            .dout(dout),
            .clka(clka),
            .cea(cea),
            .reseta(reseta),
            .clkb(clkb),
            .ceb(ceb),
            .resetb(resetb),
            .oce(oce),
            .ada(ada),
            .din(din),
            .adb(adb)
        );
    `endif // SIMULATION

endmodule
