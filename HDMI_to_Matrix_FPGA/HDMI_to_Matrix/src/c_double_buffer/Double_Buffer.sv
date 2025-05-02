// Neue Version des Double_Buffer mit flachen Ein- und Ausgängen

module Double_Buffer #(
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BANK_COUNT = 6,
    parameter int BLOCK_COUNT = 2,
    parameter int BLOCK_DATA_WIDTH_A = 32, // Write Port
    parameter int BLOCK_DATA_WIDTH_B = 8,  // Read Port
    parameter int ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A,
    parameter int ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B
)(
    input  logic                          I_rst_n,

    input  logic                          I_clka,
    input  logic                          I_write_enable,
    input  logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_A)-1:0] I_ada_flat,
    input  logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_A-1:0]       I_din_flat,

    input  logic                          I_clkb,
    input  logic                          I_read_enable,
    input  logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_B)-1:0] I_adb_flat,
    output logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0]       O_dout_flat,

    input  logic                          I_swap_trigger,
    output logic                          O_data_valid
);

    typedef enum logic { BUFFER_0, BUFFER_1 } buffer_t;
    buffer_t write_buffer;

    always_ff @(posedge I_swap_trigger or negedge I_rst_n) begin
        if (!I_rst_n) begin
            write_buffer <= BUFFER_0;
            O_data_valid <= 1'b0;
        end else begin
            write_buffer <= buffer_t'((write_buffer == BUFFER_0) ? BUFFER_1 : BUFFER_0);
            O_data_valid <= 1'b1;
        end
    end

    // Clock pulse generation
    logic write_pulse;
    logic read_pulse;
`ifdef EDGE_DETECT
    logic [1:0] clk_data_in_d;
    always_ff @(posedge I_clka or negedge I_rst_n) begin
        if (!I_rst_n) begin
            clk_data_in_d <= 0;
        end else begin
            clk_data_in_d[0] <= I_write_enable;
            clk_data_in_d[1] <= clk_data_in_d[0];
        end
    end
    assign write_pulse = clk_data_in_d[0] & ~clk_data_in_d[1];

    logic [1:0] clk_data_out_d;
    always_ff @(posedge I_clkb or negedge I_rst_n) begin
        if (!I_rst_n) begin
            clk_data_out_d <= 0;
        end else begin
            clk_data_out_d[0] <= I_read_enable;
            clk_data_out_d[1] <= clk_data_out_d[0];
        end
    end
    assign read_pulse = clk_data_out_d[0] & ~clk_data_out_d[1];
`else	
    assign write_pulse = I_write_enable;
    assign read_pulse = I_read_enable;
`endif

    // Buffer Outputs
    logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0] dout_buffer0;
    logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0] dout_buffer1;

    logic cea0, ceb0, cea1, ceb1;
    always_comb begin
        cea0 = (write_buffer == BUFFER_0);
        cea1 = (write_buffer == BUFFER_1);
        ceb0 = (write_buffer == BUFFER_1);
        ceb1 = (write_buffer == BUFFER_0);
    end

    // Zwei Single_Buffer-Instanzen
    Single_Buffer #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) buffer0 (
        .I_clka(I_clka),
        .I_cea(cea0 & write_pulse),
        .I_oce(1'b1),
        .I_reseta(~I_rst_n),
        .I_ada_flat(I_ada_flat),
        .I_din_flat(I_din_flat),
        .I_clkb(I_clkb),
        .I_ceb(ceb0 & read_pulse),
        .I_resetb(~I_rst_n),
        .I_adb_flat(I_adb_flat),
        .O_dout_flat(dout_buffer0)
    );

    Single_Buffer #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) buffer1 (
        .I_clka(I_clka),
        .I_cea(cea1 & write_pulse),
        .I_oce(1'b1),
        .I_reseta(~I_rst_n),
        .I_ada_flat(I_ada_flat),
        .I_din_flat(I_din_flat),
        .I_clkb(I_clkb),
        .I_ceb(ceb1 & read_pulse),
        .I_resetb(~I_rst_n),
        .I_adb_flat(I_adb_flat),
        .O_dout_flat(dout_buffer1)
    );

    // Ausgabe: aktive Leseseite
    always_comb begin
        if (write_buffer == BUFFER_0) begin
            O_dout_flat = dout_buffer1;
        end else begin
            O_dout_flat = dout_buffer0;
        end
    end

endmodule
