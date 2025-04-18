module Bank_Distributor #(
    parameter int CHANNEL_NUMBER = 3,
    parameter int CHANNEL_BANDWIDTH = 128,
    parameter int BANK_DEPTH = 480
)(
    input logic I_clk_in,   // at rise edge of batch_clk_in, the data is valid
    input logic [CHANNEL_BANDWIDTH-1:0] I_data_in [0:CHANNEL_NUMBER-1], // batch data input
    input logic [$clog2(BANK_DEPTH*CHANNEL_NUMBER) - 1:0] I_address_in, // batch address input

    output logic [CHANNEL_BANDWIDTH-1:0] O_data_out [0:CHANNEL_NUMBER-1], // batch data output
    output logic [$clog2(BANK_DEPTH)-1:0] O_address_out [0:CHANNEL_NUMBER-1], // batch address output
    output logic O_clk_out [0:CHANNEL_NUMBER-1] // batch clock output out
);

    // I_data_in get saved to all banks, depending on the address
    // I_data_in[0]: 0-159 -> bank 0, 160-319 -> bank 1, 320-479 -> bank 2
    // I_data_in[1]: 0-159 -> bank 1, 160-319 -> bank 2, 320-479 -> bank 0
    // I_data_in[2]: 0-159 -> bank 2, 160-319 -> bank 0, 320-479 -> bank 1

    // interne Konstanten
    localparam int GLOBAL_ADDR_BITS = $clog2(BANK_DEPTH * CHANNEL_NUMBER);
    localparam int BANK_ADDR_BITS   = $clog2(BANK_DEPTH);
    localparam int BANK_INDEX_BITS  = $clog2(CHANNEL_NUMBER);
    localparam int DEPTH_OFFSET     = BANK_DEPTH / CHANNEL_NUMBER;

    // kombinatorische Hilfssignale
    logic [CHANNEL_BANDWIDTH-1:0] comb_data_out    [0:CHANNEL_NUMBER-1];
    logic [BANK_ADDR_BITS-1:0]    comb_addr_out    [0:CHANNEL_NUMBER-1];
    logic                         comb_clk_out     [0:CHANNEL_NUMBER-1];

    
    logic [CHANNEL_BANDWIDTH-1:0] data_in_0;
    logic [CHANNEL_BANDWIDTH-1:0] data_in_1;
    logic [CHANNEL_BANDWIDTH-1:0] data_in_2;
    logic [GLOBAL_ADDR_BITS-1:0] addr_in;
    logic [CHANNEL_BANDWIDTH-1:0] data_out_0;
    logic [CHANNEL_BANDWIDTH-1:0] data_out_1;
    logic [CHANNEL_BANDWIDTH-1:0] data_out_2;
    logic [BANK_ADDR_BITS-1:0] addr_out_0;
    logic [BANK_ADDR_BITS-1:0] addr_out_1;
    logic [BANK_ADDR_BITS-1:0] addr_out_2;

    int channel_offset = 0;
    int new_channel [0:CHANNEL_NUMBER-1];

    // kontinuierliche Zuordnung (reaktiv auf Adress-/Dateneingang)
    always_comb begin

        if (I_address_in < DEPTH_OFFSET) begin
            channel_offset = 0;
        end else if (I_address_in < 2*DEPTH_OFFSET) begin
            channel_offset = 1;
        end else begin
            channel_offset = 2;
        end

        for (int ch = 0; ch < CHANNEL_NUMBER; ch++) begin
            // Data Mapping
            new_channel[ch] = (ch + channel_offset) % CHANNEL_NUMBER;
            O_data_out[new_channel[ch]] = I_data_in[ch];

            // Address Mapping
            O_address_out[ch] = (I_address_in + new_channel[ch] * DEPTH_OFFSET) % BANK_DEPTH;
            
            // Clock Mapping
            O_clk_out[ch] = I_clk_in;
        end
  
    end

    `ifndef REAL
        `define SIMULATION 0
    `endif

    `ifdef SIMULATION
        always_comb begin
            data_in_0 = I_data_in[0];
            data_in_1 = I_data_in[1];
            data_in_2 = I_data_in[2];
            addr_in = I_address_in;
            addr_out_0 = O_address_out[0];
            addr_out_1 = O_address_out[1];
            addr_out_2 = O_address_out[2];
            data_out_0 = O_data_out[0];
            data_out_1 = O_data_out[1];
            data_out_2 = O_data_out[2];
        end
    `endif
endmodule
