// SDPB-basierter Ringbuffer
module SDPB_RingBuffer #(
    parameter int ADDRESS_DEPTH = 512,
    parameter int DATA_WIDTH = 32
)(
    input  logic clk,
    input  logic rst,

    // Write Interface
    input  logic                  write_en,
    input  logic [DATA_WIDTH-1:0] write_data,

    // Read Interface
    input  logic                  read_en,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic                  data_valid
);

    // Interne Adresszeiger
    logic [$clog2(ADDRESS_DEPTH)-1:0] wr_ptr = 0;
    logic [$clog2(ADDRESS_DEPTH)-1:0] rd_ptr = 0;

    // Interne Zustandskontrolle
    logic [$clog2(ADDRESS_DEPTH):0] fill_level = 0;

    // RAM-Schnittstellen
    logic [DATA_WIDTH-1:0] ram_dout;

    SDPB_sim #(
        .ADDRESS_DEPTH_A(ADDRESS_DEPTH),
        .DATA_WIDTH_A(DATA_WIDTH),
        .ADDRESS_DEPTH_B(ADDRESS_DEPTH),
        .DATA_WIDTH_B(DATA_WIDTH)
    ) ram_inst (
        .clka(clk),
        .cea(write_en),
        .oce(1'b1),
        .reseta(rst),
        .ada(wr_ptr),
        .din(write_data),

        .clkb(clk),
        .ceb(read_en),
        .resetb(rst),
        .adb(rd_ptr),
        .dout(ram_dout)
    );

    // Ausgabe und Pointer-Logik
    assign read_data = ram_dout;
    assign data_valid = (fill_level > 0);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fill_level <= 0;
        end else begin
            if (write_en && (fill_level < ADDRESS_DEPTH)) begin
                wr_ptr <= wr_ptr + 1;
                fill_level <= fill_level + 1;
            end
            if (read_en && (fill_level > 0)) begin
                rd_ptr <= rd_ptr + 1;
                fill_level <= fill_level - 1;
            end
        end
    end

endmodule
