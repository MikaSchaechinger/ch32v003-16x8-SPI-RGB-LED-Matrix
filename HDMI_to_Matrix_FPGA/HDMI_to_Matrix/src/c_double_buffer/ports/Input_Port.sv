module Input_Port #(
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BANK_COUNT = 6,
    parameter int BLOCK_COUNT = 2,
    parameter int BLOCK_DATA_WIDTH_A = 32,  // Write Port
    parameter int ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A // Write Port

) (
    input  logic [$clog2(ADDRESS_NUMBER_A)-1:0] I_address,
    input  logic [(BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_A-1:0] I_data_flat,

    output logic [(BANK_COUNT*BLOCK_COUNT)*$clog2(ADDRESS_NUMBER_A)-1:0] O_addresses_flat,
    output logic [(BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_A-1:0] O_data_flat
);
    localparam DATA_COUNT = BANK_COUNT * BLOCK_COUNT; 

    logic [2:0] addr_mod6;
    logic [1:0] addr_mod3;
    logic [1:0] addr_mod2;
    assign addr_mod6 = I_address % 6;
    assign addr_mod3 = I_address % 3;
    assign addr_mod2 = I_address % 2;


    // ========== Data Distribution ==========

    // Step 1: Split Data
    logic [BLOCK_DATA_WIDTH_A-1:0] s1_data_split [DATA_COUNT-1:0];

    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            s1_data_split[i] = I_data_flat[i*BLOCK_DATA_WIDTH_A +: BLOCK_DATA_WIDTH_A];
        end
    end

    // Step 2: Distribute Data
    logic [BLOCK_DATA_WIDTH_A-1:0] s2_data_swap [DATA_COUNT-1:0];

    always @* begin
        case (addr_mod6)
            0, 1, 2: begin
                for (int i = 0; i < DATA_COUNT; i++) begin
                    s2_data_swap[i] = s1_data_split[i];
                end
            end
            3, 4, 5: begin
                // Swap data 0 with 1, 2 with 3, 4 with 5, ...
                for (int i = 0; i < DATA_COUNT; i++) begin
                    if (i % 2 == 0) begin
                        // O_data[i] = s1_data_split[i + 1];
                        s2_data_swap[i + 1] = s1_data_split[i];
                    end else begin
                        // O_data[i] = s1_data_split[i - 1];
                        s2_data_swap[i - 1] = s1_data_split[i];
                    end
                end
            end
        endcase
    end

    // Step 3: Combine to one flat array

    logic [(DATA_COUNT)*BLOCK_DATA_WIDTH_A-1:0] s3_data_flat;
    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            s3_data_flat[i*BLOCK_DATA_WIDTH_A +: BLOCK_DATA_WIDTH_A] = s2_data_swap[i];
        end
    end

    // Step 4: Split the Data into 3 parts

    logic [(BLOCK_DATA_WIDTH_A*DATA_COUNT/3)-1:0] s4_data_split_3 [2:0];
    always @* begin
        for (int i = 0; i < 3; i++) begin
            s4_data_split_3[i] = s3_data_flat[i*BLOCK_DATA_WIDTH_A*DATA_COUNT/3 +: BLOCK_DATA_WIDTH_A*DATA_COUNT/3];
        end
    end

    // Step 5: Rotate the Data by mod3 

    logic [(BLOCK_DATA_WIDTH_A*DATA_COUNT/3)-1:0] s5_data_rotated [2:0];

    always @* begin
        case (addr_mod3)
            0: begin
                s5_data_rotated[0] = s4_data_split_3[0];
                s5_data_rotated[1] = s4_data_split_3[1];
                s5_data_rotated[2] = s4_data_split_3[2];
            end
            1: begin
                s5_data_rotated[0] = s4_data_split_3[2];
                s5_data_rotated[1] = s4_data_split_3[0];
                s5_data_rotated[2] = s4_data_split_3[1];
            end
            2: begin
                s5_data_rotated[0] = s4_data_split_3[1];
                s5_data_rotated[1] = s4_data_split_3[2];
                s5_data_rotated[2] = s4_data_split_3[0];
            end    
        endcase
    end

    // Step 6: Combine the rotated data into one flat array

    always @* begin
        for (int i = 0; i < 3; i++) begin
            O_data_flat[i*BLOCK_DATA_WIDTH_A*DATA_COUNT/3 +: BLOCK_DATA_WIDTH_A*DATA_COUNT/3] = s5_data_rotated[i];
        end
    end


    // ========== Address Calculation ==========

    // The address pattern is repeated every 6 addresses with the following offset:
    logic [$clog2(ADDRESS_NUMBER_A/6)-1:0] addr_offset;
    assign addr_offset = I_address / 6;

    // Pattern calculation
    // Block 0,0: 0, 4, 2, 1, 5, 3, Repeat 
    // Block 0,1: 1, 5, 3, 0, 4, 2, Repeat
    // Block 1,0: same as Block 0,0
    // Block 1,1: same as Block 0,1

    // Block 2,0: Block 0,0 + 2 % 6
    // Block 2,1: Block 0,1 + 2 % 6
    // Block 3,0: Block 0,0 + 2 % 6
    // Block 3,1: Block 0,1 + 2 % 6

    // Block 4,0: Block 0,0 + 4 % 6
    // Block 4,1: Block 0,1 + 4 % 6
    // Block 5,0: Block 0,0 + 4 % 6
    // Block 5,1: Block 0,1 + 4 % 6


    logic [$clog2(6)-1:0] pattern0;
    logic [$clog2(6)-1:0] pattern1;

    always_comb begin
        case (addr_mod6)
            0: begin
                pattern0 = 0;
                pattern1 = 1;
            end
            1: begin
                pattern0 = 4;
                pattern1 = 5;
            end
            2: begin
                pattern0 = 2;
                pattern1 = 3;
            end
            3: begin
                pattern0 = 1;
                pattern1 = 0;
            end
            4: begin
                pattern0 = 5;
                pattern1 = 4;
            end
            5: begin
                pattern0 = 3;
                pattern1 = 2;
            end
        endcase
    end


    // always @* begin
    //     for (int i = 0; i < DATA_COUNT; i++) begin
    //         O_addresses[i] = addr_offset * 6 + ((i % 2 == 0 ? pattern0 : pattern1) + ((i >> 2) * 2) ) % 6;
    //     end
    // end

    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            O_addresses_flat[i*$clog2(ADDRESS_NUMBER_A) +: $clog2(ADDRESS_NUMBER_A)] = addr_offset * 6 + ((i % 2 == 0 ? pattern0 : pattern1) + ((i >> 2) * 2)) % 6;
        end
    end


endmodule