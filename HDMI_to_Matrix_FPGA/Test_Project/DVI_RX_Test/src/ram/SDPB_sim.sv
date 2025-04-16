// Simuliertes SDPB RAM-Modul für Gowin-kompatibles Verhalten

module SDPB_sim #(
    parameter int ADDRESS_DEPTH_A = 512,
    parameter int DATA_WIDTH_A = 32,
    parameter int ADDRESS_DEPTH_B = 1024,
    parameter int DATA_WIDTH_B = 16
)(
    input logic                     clka,
    input logic                     cea,
    input logic                     oce,
    input logic                     reseta,
    input logic [$clog2(ADDRESS_DEPTH_A)-1:0] ada,
    input logic [DATA_WIDTH_A-1:0] din,

    input logic                     clkb,
    input logic                     ceb,
    input logic                     resetb,
    input logic [$clog2(ADDRESS_DEPTH_B)-1:0] adb,
    output logic [DATA_WIDTH_B-1:0] dout
);

    // Speicherblock: ein gemeinsamer RAM, Byte-adressiert
    localparam int TOTAL_BITS = ADDRESS_DEPTH_A * DATA_WIDTH_A;
    localparam int MEMORY_SIZE = TOTAL_BITS / 8; // in Bytes
    logic [7:0] memory [0:MEMORY_SIZE-1];

    // Internes Register für synchrone Ausgabe
    logic [DATA_WIDTH_B-1:0] dout_next;

    // Port A: Schreibzugriff
    always_ff @(posedge clka or posedge reseta) begin
        if (reseta) begin
            // keine Initialisierung notwendig
        end else if (cea) begin
            for (int i = 0; i < DATA_WIDTH_A/8; i++) begin
                memory[ada * (DATA_WIDTH_A/8) + i] <= din[i*8 +: 8];
            end
        end
    end

    // Port B: Lesezugriff
    always_ff @(posedge clkb or posedge resetb) begin
        if (resetb) begin
            dout_next <= '0;
        end else if (ceb) begin
            for (int i = 0; i < DATA_WIDTH_B/8; i++) begin
                dout_next[i*8 +: 8] <= memory[adb * (DATA_WIDTH_B/8) + i];
            end
        end
    end

    // Optionales Ausgabe-Register (output clock enable)
    always_ff @(posedge clkb) begin
        if (oce)
            dout <= dout_next;
    end

endmodule