module DVI_RX_SIM #(
    parameter int H_ACTIVE = 800,
    parameter int H_TOTAL  = 1056,
    parameter int V_ACTIVE = 600,
    parameter int V_TOTAL  = 628
)(
    input  logic clk,       // Input-Takt für Simulation
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

    // Lokale Parameter
    localparam int H_SYNC_START = H_ACTIVE + 8;
    localparam int H_SYNC_END   = H_SYNC_START + 8;

    localparam int V_SYNC_START = V_ACTIVE + 1;
    localparam int V_SYNC_END   = V_SYNC_START + 2;


    // Pixelzähler
    int unsigned hcount = 0;
    int unsigned vcount = 0;

    logic pixclk = 0;

    // Pixeltakt (Clock Divider 1:2)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pixclk <= 0;
        else
            pixclk <= ~pixclk;
    end

    // Horizontal- & Vertikalzähler
    always_ff @(posedge pixclk or negedge rst_n) begin
        if (!rst_n) begin
            hcount <= 0;
            vcount <= 0;
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
        end
    end

    // Clock-Ausgang
    always_ff @(posedge clk)
        O_rgb_clk <= pixclk;

    // Video-Synchronisation
    always_comb begin
        O_rgb_de = (hcount < H_ACTIVE) && (vcount < V_ACTIVE);
        O_rgb_hs = (hcount >= H_SYNC_START) && (hcount < H_SYNC_END);
        O_rgb_vs = (vcount >= V_SYNC_START) && (vcount < V_SYNC_END);
    end

    // Farb-Generator (einfaches Testmuster)
    logic [3:0] hcount_region;

    always @(*) begin
        logic [3:0] region;
        region = hcount[9:6];

        if (O_rgb_de) begin
            case (region)
                4'h0: begin O_rgb_r = 8'hFF; O_rgb_g = 8'h00; O_rgb_b = 8'h00; end
                4'h1: begin O_rgb_r = 8'h00; O_rgb_g = 8'hFF; O_rgb_b = 8'h00; end
                4'h2: begin O_rgb_r = 8'h00; O_rgb_g = 8'h00; O_rgb_b = 8'hFF; end
                4'h3: begin O_rgb_r = 8'hFF; O_rgb_g = 8'hFF; O_rgb_b = 8'h00; end
                4'h4: begin O_rgb_r = 8'h00; O_rgb_g = 8'hFF; O_rgb_b = 8'hFF; end
                4'h5: begin O_rgb_r = 8'hFF; O_rgb_g = 8'h00; O_rgb_b = 8'hFF; end
                4'h6: begin O_rgb_r = 8'h80; O_rgb_g = 8'h80; O_rgb_b = 8'h80; end
                default: begin O_rgb_r = 8'h00; O_rgb_g = 8'h00; O_rgb_b = 8'h00; end
            endcase
        end else begin
            O_rgb_r = 8'h00;
            O_rgb_g = 8'h00;
            O_rgb_b = 8'h00;
        end
    end

    // PLL-Signale (konstant simuliert)
    assign O_pll_phase      = 4'd4;  // 90°
    assign O_pll_phase_lock = 1'b1;  // locked

endmodule
