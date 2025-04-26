// Double_Buffer: Kapselt zwei Single_Buffer-Instanzen mit Umschaltlogik

module Double_Buffer #(
    parameter int ADDRESS_DEPTH = 512,
    parameter int BANK_COUNT = 3,
    parameter int BLOCK_COUNT = 4,
    parameter int BLOCK_DATA_WIDTH = 32,
    parameter int BANDWIDTH = BLOCK_COUNT * BLOCK_DATA_WIDTH
)(
    input  logic                          rst_n,

    input  logic                          clka,                     // clk_data_in
    input  logic                          clk_data_in,              // clk_data_in
    input  logic [$clog2(ADDRESS_DEPTH)-1:0] ada [BANK_COUNT-1:0],  // address
    input  logic [BANDWIDTH-1:0]          din [BANK_COUNT-1:0],     // data in

    input  logic                          clkb,                     // clk_data_out
    input  logic                          clk_data_out,             // clk_data_out
    input  logic [$clog2(ADDRESS_DEPTH)-1:0] adb [BANK_COUNT-1:0],
    output logic [BANDWIDTH*BANK_COUNT-1:0]  dout_flat,

    input  logic                          swap_trigger,             // z. B. bei frame_complete
    output logic                          data_valid                // High after first swap_trigger
);


    typedef enum logic  { 
        BUFFER_0,
        BUFFER_1
    } buffer_t;

    buffer_t write_buffer;

    always_ff @(posedge swap_trigger or negedge rst_n) begin
        if (!rst_n) begin
            write_buffer <= BUFFER_0;
            data_valid   <= 1'b0;
        end else begin
            write_buffer <= buffer_t'((write_buffer == BUFFER_0) ? BUFFER_1 : BUFFER_0);
            data_valid   <= 1'b1;
        end
    end


    // Create a pulese from clk_data_in and clk_data_out
    logic write_pulse;
    logic [1:0] clk_data_in_d;
    always_ff @(posedge clka or negedge rst_n) begin
        if (!rst_n) begin
            clk_data_in_d <= 0;
        end else begin
            clk_data_in_d[0] <= clk_data_in;
            clk_data_in_d[1] <= clk_data_in_d[0];
        end
    end
    assign write_pulse = clk_data_in_d[0] & ~clk_data_in_d[1];    // rising edge of clk_data_in

    logic read_pulse;
    logic [1:0] clk_data_out_d;
    always_ff @(posedge clkb or negedge rst_n) begin
        if (!rst_n) begin
            clk_data_out_d <= 0;
        end else begin
            clk_data_out_d[0] <= clk_data_out;
            clk_data_out_d[1] <= clk_data_out_d[0];
        end
    end
    assign read_pulse = clk_data_out_d[0] & ~clk_data_out_d[1];  // rising edge of clk_data_out

            

    // Buffer-Outputs
    logic [BANDWIDTH*BANK_COUNT-1:0] dout_buffer0;
    logic [BANDWIDTH*BANK_COUNT-1:0] dout_buffer1;

    logic cea0;
    logic ceb0;
    logic cea1;
    logic ceb1;
    always_comb begin
        cea0 = (write_buffer == BUFFER_0);
        cea1 = (write_buffer == BUFFER_1);
        ceb0 = (write_buffer == BUFFER_1);
        ceb1 = (write_buffer == BUFFER_0);
    end

    // Zwei Single_Buffer-Instanzen
    Single_Buffer #(
        .ADDRESS_DEPTH(ADDRESS_DEPTH),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH(BLOCK_DATA_WIDTH)
    ) buffer0 (
        .clka(clka),
        .cea(cea0 & write_pulse),
        .oce(1'b1),         // always enabled
        .reseta(~rst_n),    // must be asynchronous
        .ada(ada),
        .din(din),

        .clkb(clkb),
        .ceb(ceb0 & read_pulse),
        .resetb(~rst_n),    // must be asynchronous
        .adb(adb),
        .dout_flat(dout_buffer0)
    );

    Single_Buffer #(
        .ADDRESS_DEPTH(ADDRESS_DEPTH),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH(BLOCK_DATA_WIDTH)
    ) buffer1 (
        .clka(clka),
        .cea(cea1 & write_pulse),
        .oce(1'b1),         // always enabled
        .reseta(~rst_n),    // must be asynchronous
        .ada(ada),
        .din(din),

        .clkb(clkb),
        .ceb(ceb1 & read_pulse),
        .resetb(~rst_n),    // must be asynchronous
        .adb(adb),
        .dout_flat(dout_buffer1)
    );

    // Ausgabe: aktive Leseseite
    always_comb begin
        if (write_buffer == BUFFER_0) begin
            dout_flat = dout_buffer1;
        end else begin
            dout_flat = dout_buffer0;
        end
    end


    // Debugging
    logic [BANDWIDTH-1:0] din0;
    assign din0 = din[0];


endmodule
