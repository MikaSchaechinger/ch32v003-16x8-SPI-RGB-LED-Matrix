module Output_Port #(
    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BANK_COUNT = 6,
    parameter int BLOCK_COUNT = 2,
    parameter int BLOCK_DATA_WIDTH_B = 8,   // Read Port
    parameter int ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B // Read Port
) (
    input logic I_rst_n,
    input logic I_clkb,
    // IO to Buffer
    output logic [$clog2(ADDRESS_NUMBER_B)-1:0] O_addresses_common,
    input logic [(BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_B-1:0] I_data_flat,

    // IO to Output Logic
    input logic [$clog2(ADDRESS_NUMBER_B)-1:0] I_address,
    output logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0] O_data_flat
);

    // ========== Address Buffer for Date structuration ==========
    logic [$clog2(ADDRESS_NUMBER_B)-1:0] address_buffered;

    always_ff @(posedge I_clkb or negedge I_rst_n) begin
        if (!I_rst_n) begin
            address_buffered <= 0;
        end else begin
            address_buffered <= I_address;
        end
    end


    // 4x8 Bits lay together, but only 8 Bit per Block are read out.
    // Pattern for each Block equal:
    // 0, 2, 4
    // This *4 and 4 Times with offset 0, 1, 2, 3
    // e.g. 0, 8, 16, 1, 9, 17, 2, 10, 18, 3, 11, 19
    // Then the half of the first Data Block is finished.
    // Second half pattern is: 1, 3, 5 and the data is swapped 0,0 with 0,1, 1,0 with 1,1, 2,0 with 2,1, ...
    // Same with offset 0, 1, 2, 3 as before.
    // This repeats every 6x4 = 24 addresses.
    localparam int TOTAL_WIDTH = (BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_B;
    localparam DATA_COUNT = BANK_COUNT * BLOCK_COUNT;

    logic [$clog2(24)-1:0] addr_buf_mod24;
    logic [$clog2(3)-1:0] addr_buf_mod3;
    assign addr_buf_mod24 = address_buffered % 24;
    assign addr_buf_mod3 = address_buffered % 3;

    // Thought model. We swap data inside of the Bank-Block grid, until the all data of for each SPI-Stream is inside of its own Block.

    // Goal 1: The Data is distributed over multiple Banks and Blocks. Colors for one one Stream must ley together in the same Block. 
    // Because of Bandwidth limitations (32 Bit/4 Byte per Block), the 8 Byte are distributed over Block 0 and Block 1.
    // Byte 4-7 of each Color must be swapped. This is done by swapping the (one) Byte form Block 0 and Block 1 when addr_buf_mod24 >= 12.

    // Step 1: Split the Data into DATA_COUNT (12) parts
    logic [BLOCK_DATA_WIDTH_B-1:0] s1_split_data [DATA_COUNT-1:0];
    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            s1_split_data[i] = I_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B];
        end
    end

    // Step 2: Swap Data based on address mod 24
    logic [BLOCK_DATA_WIDTH_B-1:0] s2_data_swap [DATA_COUNT-1:0];
    always @* begin
        if (addr_buf_mod24 < 12) begin
            // No swap
            for (int i = 0; i < DATA_COUNT; i++) begin
                s2_data_swap[i] = s1_split_data[i];
            end
        end else begin
            for (int i = 0; i < DATA_COUNT; i += 2) begin
                s2_data_swap[i]   = s1_split_data[i+1];
                s2_data_swap[i+1] = s1_split_data[i];
            end
        end
    end

    // Step 3: Combine to one flat array
    logic [TOTAL_WIDTH-1:0] s3_data_flat;
    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            s3_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B] = s2_data_swap[i];
        end
    end

    // Goal 2: Now each Color inside of one Block is together. Next the 3 colors must match together.
    // Green and Blue have an offset of 1/3 btw 2/3 of the complete Data. Because the colors are read cyclically (rgbrgbrgb...), addr_buf_mod3 is used to determine the offset.

    // Step 4: Merge the Data into 3 parts
    logic [TOTAL_WIDTH/3-1:0] s4_split_data [2:0];
    always @* begin
        for (int i = 0; i < 3; i++) begin
            s4_split_data[i] = s3_data_flat[i*TOTAL_WIDTH/3 +: TOTAL_WIDTH/3];
        end
    end

    // Step 5: Rotate the Data by mod3
    logic [TOTAL_WIDTH/3-1:0] s5_data_rotated [2:0];
    always @* begin
        case (addr_buf_mod3)
            0: begin
                s5_data_rotated[0] = s4_split_data[0];
                s5_data_rotated[1] = s4_split_data[1];
                s5_data_rotated[2] = s4_split_data[2];
            end
            1: begin
                s5_data_rotated[0] = s4_split_data[1];
                s5_data_rotated[1] = s4_split_data[2];
                s5_data_rotated[2] = s4_split_data[0];
            end
            2: begin
                s5_data_rotated[0] = s4_split_data[2];
                s5_data_rotated[1] = s4_split_data[0];
                s5_data_rotated[2] = s4_split_data[1];
            end
        endcase
    end

    // Goal 3: Now inside of each Block the Data is together. Now the Data must be sorted. Imagine The 6 Banks with its 2 Blocks as a 2D Grid. 
    // B(i, k) = Block i, Bank k. 
    // In the moment, the Data is B(0,0), B(0,1), B(1,0), B(1,1), ...
    // The Data must be sorted to B(0,0), B(1,0), B(2,0), B(3,0), B(4,0), B(5,0), B(0,1), B(1,1), ...

    // Step 6: Combine the rotated data into one flat array
    logic [TOTAL_WIDTH-1:0] s6_data_flat;
    always @* begin
        for (int i = 0; i < 3; i++) begin
            s6_data_flat[i*TOTAL_WIDTH/3 +: TOTAL_WIDTH/3] = s5_data_rotated[i];
        end
    end

    // Step 7: Split the Data into 12 (DATA_COUNT) parts again
    logic [BLOCK_DATA_WIDTH_B-1:0] s7_split_data [DATA_COUNT-1:0];
    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            s7_split_data[i] = s6_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B];
        end
    end

    // Step 8: Rearrange the Data (decribed in Goal 3)
    logic [BLOCK_DATA_WIDTH_B-1:0] s8_data_rearranged [DATA_COUNT-1:0];
    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            s8_data_rearranged[i] = s7_split_data[(i % BANK_COUNT) * BLOCK_COUNT + (i / BANK_COUNT)];
        end
    end

    // Step 9: Combine to one flat array and write to output
    always @* begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            O_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B] = s8_data_rearranged[i];
        end
    end







 
    // ========== Address Calculation ==========
    
    logic [$clog2(24)-1:0] addr_mod24;
    logic [$clog2(3)-1:0] addr_mod3;
    assign addr_mod24 = I_address % 24;
    assign addr_mod3 = I_address % 3;

    logic [$clog2(ADDRESS_NUMBER_B/24)-1:0] addr_offset;
    assign addr_offset = I_address / 24;

    // Pattern Generation with mod 3: 0, 1, 2, Repeat
    // is already addr_mod3

    // Base Pattern *8: 0, 8, 16, Repeat
    logic [$clog2(3*8)-1:0] base_pattern;
    assign base_pattern = addr_mod3 * 8;

    // Offset generation: 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, Repeat
    logic [$clog2(3+1)-1:0] offset_div3_mod4;
    assign offset_div3_mod4 = (I_address / 3) % 4;

    // Pattern with offset: 0, 8, 16, 1, 9, 17, 2, 10, 18, 3, 11, 19, Repeat
    logic [$clog2(3*8)-1:0] pattern_with_offset;
    assign pattern_with_offset = base_pattern + offset_div3_mod4;

    // Extra offset of 4, when addr_mod24 >= 12
    logic [$clog2(3*8)-1:0] final_pattern;
    assign final_pattern = (addr_mod24 < 12) ? pattern_with_offset : pattern_with_offset + 4;


    // Address is the Samen for all Banks and Blocks
    assign O_addresses_common = addr_offset * 24 + final_pattern;



endmodule