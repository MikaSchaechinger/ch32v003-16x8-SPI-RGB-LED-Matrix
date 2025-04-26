
module Buffer_Write_Address_Calculator #(
    parameter int BANK_COUNT = 3,
    parameter int BLOCK_DEPTH = 480
) (
    input  logic [$clog2(BLOCK_DEPTH)-1:0] I_global_address, // batch address input

    output logic [$clog2(BLOCK_DEPTH)-1:0] O_bank_address [0:BANK_COUNT-1] // batch address output
);

    logic [$clog2(BANK_COUNT)-1:0] bank_offset;
    logic [$clog2(BLOCK_DEPTH)-1:0] bank_local_addr;

    /*
    * Global Address:  0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |  9 | ... | 479
    * -------------------+---+---+---+---+---+---+---+---+----+-----+-----
    * bank_offset:     0 | 1 | 2 | 0 | 1 | 2 | 0 | 1 | 2 |  0 | ... |   0
    * bank_local_addr: 0 | 0 | 0 | 0 | 3 | 3 | 3 | 6 | 6 |  6 | ... | 477
    * Block Address 0: 0 | 2 | 1 | 3 | 5 | 4 | 6 | 8 | 7 |  9 | ... | 478
    * Block Address 1: 1 | 0 | 2 | 4 | 3 | 5 | 7 | 6 | 8 | 10 | ... | 479
    * Block Address 2: 2 | 1 | 0 | 5 | 4 | 3 | 8 | 7 | 6 | 11 | ... | 487
    */

    always_comb begin
        // Vorberechnung
        bank_offset       = I_global_address % BANK_COUNT;
        bank_local_addr = (I_global_address / BANK_COUNT) * BANK_COUNT;


        // Bankzuordnung
        for (int color = 0; color < BANK_COUNT; color++) begin
            O_bank_address[color] = bank_local_addr + (color + BANK_COUNT - bank_offset) % BANK_COUNT;
        end
    end


`ifndef REAL
    `define SIMULATION 0
`endif 


`ifdef SIMULATION
    logic [$clog2(BLOCK_DEPTH)-1:0] bank_address_0;
    logic [$clog2(BLOCK_DEPTH)-1:0] bank_address_1;
    logic [$clog2(BLOCK_DEPTH)-1:0] bank_address_2;

    always_comb begin
        bank_address_0 = O_bank_address[0];
        bank_address_1 = O_bank_address[1];
        bank_address_2 = O_bank_address[2];
    end
`endif




endmodule