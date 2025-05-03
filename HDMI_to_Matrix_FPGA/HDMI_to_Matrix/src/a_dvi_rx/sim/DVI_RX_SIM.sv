// DVI_RX_SIM mit Stripe-Codierung und dynamischem H_BLANK
module DVI_RX_SIM #(
    parameter int H_ACTIVE = 800,
    parameter int H_BLANK  = 256, // min 16
    parameter int V_ACTIVE = 600,
    parameter int V_BLANK  = 28   // min 4
)(
    input  logic clk,
    input  logic rst_n,

    output logic [3:0] O_pll_phase,
    output logic       O_pll_phase_lock,
    output logic       O_rgb_clk,
    output logic       O_rgb_vs,
    output logic       O_rgb_hs,
    output logic       O_rgb_de,
    output logic [7:0] O_rgb_r,
    output logic [7:0] O_rgb_g,
    output logic [7:0] O_rgb_b
);

    // Abgeleitete Parameter
    localparam int H_TOTAL = H_ACTIVE + H_BLANK;
    localparam int V_TOTAL = V_ACTIVE + V_BLANK;

    // Mindestgröße prüfen (mind. 16 Horizontal-Blanking, 4 Vertikal-Blanking)
    initial begin
        if (H_BLANK < 16) begin
            $fatal("H_BLANK zu klein! Muss mindestens 16 betragen. Aktuell: %0d", H_BLANK);
        end
        if (V_BLANK < 4) begin
            $fatal("V_BLANK zu klein! Muss mindestens 4 betragen. Aktuell: %0d", V_BLANK);
        end
    end

    // Sync-Bereiche
    localparam int H_SYNC_START = H_ACTIVE + 2;
    localparam int H_SYNC_END   = H_TOTAL - 2;
    localparam int V_SYNC_START = V_ACTIVE + 1;
    localparam int V_SYNC_END   = V_TOTAL - 1;

    // Pixelzähler
    int unsigned hcount = 0;
    int unsigned vcount = 0;

    logic pixclk = 0;
    logic [3:0] stripe_id;

    // Pixeltakt (Clock Divider 1:2)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pixclk <= 0;
        else
            pixclk <= ~pixclk;
    end

    // Clock-Ausgang
    always_ff @(posedge clk)
        O_rgb_clk <= pixclk;

    // Horizontal- & Vertikalzähler + Stripe-Zähler
    always_ff @(posedge pixclk or negedge rst_n) begin
        if (!rst_n) begin
            hcount <= H_TOTAL - 1;
            vcount <= V_TOTAL - 1;
            stripe_id <= 0;
        end else begin
            if (hcount == H_TOTAL - 1) begin
                hcount <= 0;
                if (vcount == V_TOTAL - 1)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end else begin
                hcount <= hcount + 1;
            end

            if (O_rgb_hs || O_rgb_vs)
                stripe_id <= 0;
            else if (hcount % 8 == 7 && hcount <= H_ACTIVE)
                stripe_id <= stripe_id + 1;
        end
    end

    // Video-Synchronisation
    always_comb begin
        O_rgb_de = (hcount < H_ACTIVE) && (vcount < V_ACTIVE);
        O_rgb_hs = (hcount >= H_SYNC_START) && (hcount < H_SYNC_END);
        O_rgb_vs = (vcount >= V_SYNC_START) && (vcount < V_SYNC_END);
    end

    // Farb-Generator: Codierung analog zur Matrix_Buffer_tb
    always_comb begin
        if (O_rgb_de) begin
            O_rgb_r = {stripe_id[3:0], 4'b0001};  // z. B. 0x31
            O_rgb_g = {stripe_id[3:0], 4'b0011};  // z. B. 0x33
            O_rgb_b = {stripe_id[3:0], 4'b0111};  // z. B. 0x37
        end else begin
            O_rgb_r = 8'h00;
            O_rgb_g = 8'h00;
            O_rgb_b = 8'h00;
        end
    end

    // PLL-Signale (konstant simuliert)
    assign O_pll_phase      = 4'd4;
    assign O_pll_phase_lock = 1'b1;

endmodule
