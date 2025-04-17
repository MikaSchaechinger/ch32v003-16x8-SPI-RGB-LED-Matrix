module Pixel_Buffer #(
    parameter int COLOR_COUNT = 3, // Number of colors (RGB)
    parameter int BATCH_SIZE = 8, // Number of pixels per batch
)(
    input logic clk;
    input logic rst_n,

    input logic output_ready,
    
    input logic I_new_data,
    input logic [BATCH_SIZE*8-1:0] I_pixel_data [COLOR_COUNT-1:0], // RGB data for the batch

    output logic O_data_available,
    output logic [7:0] O_pixel_data [BATCH_SIZE-1:0] // One Output Array

    output logic new_image,
    output logic new_column,
    output logic next_data
);

    // Local parameters
    localparam int RING_BUFFER_SIZE = 512; // Size of the ring buffer

    // Internal signals
    logic [7:0] pixel_data [COLOR_COUNT-1:0][BATCH_SIZE-1:0]; // Buffer for pixel data
    logic [COLOR_COUNT-1:0] data_valid; // Data valid signals for each color channel
    logic [COLOR_COUNT-1:0] read_en; // Read enable signals for each color channel


    genvar ring;
    generate 
        for (ring = 0; ring < COLOR_COUNT; ring++) begin : color_buffer
            // Instantiate the ring buffer for each color channel
            SDPB_RingBuffer #(
                .ADDRESS_DEPTH(RING_BUFFER_SIZE),
                .DATA_WIDTH(8*BATCH_SIZE) // 8 bits per pixel * BATCH_SIZE pixels
            ) ring_buffer_inst (
                .clk(clk),
                .rst_n(rst_n),
                .write_en(I_new_data),
                .write_data(I_pixel_data[ring]),
                .read_en(read_en[ring]),
                .read_data(pixel_data[ring]),
                .data_valid(data_valid[ring])
            );
        end
    endgenerate



    // Local parameters
    typedef enum logic [2:0] {
        S0_IDLE,
        S1_RED,
        S2_PROCESS_RED,
        S3_GREEN,
        S4_PROCESS_GREEN,
        S5_BLUE,
        S6_PROCESS_BLUE,
        S7_SYNC
    } state_t;
    state_t current_state, next_state, last_state;



    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S0_IDLE;
        end else begin
            last_state <= current_state;
            current_state <= next_state;
            
            if (next_state == S2_PROCESS_RED) begin
                O_pixel_data[0] <= pixel_data[0]; // Output red data
            end else if (next_state == S4_PROCESS_GREEN) begin
                O_pixel_data[1] <= pixel_data[1]; // Output green data
            end else if (next_state == S6_PROCESS_BLUE) begin
                O_pixel_data[2] <= pixel_data[2]; // Output blue data
            end
        end
    end


    always_comb begin
        case (current_state)
            S0_IDLE: begin
                next_state = S1_RED;
                O_data_available = 0; // No data available in idle state
            end
            S1_RED: begin                
                if (data_valid[0]) begin
                    next_state = S2_PROCESS_RED;
                    read_en = 3'b001; // Enable read for red channel
                end else begin
                    next_state = S1_RED;
                    read_en = 3'b000; // Disable read for red channel
                end
                if (last_state == S0_IDLE) begin
                    O_data_available = 0; // No data available after reset
                end else begin
                    O_data_available = 1; // Data is available after processing
                end
            end
            S2_PROCESS_RED: begin
                read_en = 3'b000; // Disable read for red channel
                next_state = S3_GREEN;
                O_data_available = 0; // Data is available at the next cycle
            end
            S3_GREEN: begin
                if (data_valid[1]) begin
                    next_state = S4_PROCESS_GREEN;
                    read_en = 3'b010; // Enable read for green channel
                end else begin
                    next_state = S3_GREEN;
                    read_en = 3'b000; // Disable read for green channel
                end
                O_data_available = 1; // Data is available after processing
            end
            S4_PROCESS_GREEN: begin
                read_en = 3'b000; // Disable read for green channel
                next_state = S5_BLUE;
                O_data_available = 0; // Data is available at the next cycle
            end
            S5_BLUE: begin
                if (data_valid[2]) begin
                    next_state = S6_PROCESS_BLUE;
                    read_en = 3'b100; // Enable read for blue channel
                end else begin
                    next_state = S5_BLUE;
                    read_en = 3'b000; // Disable read for blue channel
                end
                O_data_available = 1; // Data is available after processing
            end
            S6_PROCESS_BLUE: begin
                read_en = 3'b000; // Disable read for blue channel
                next_state = S7_SYNC;
                O_data_available = 0; // Data is available at the next cycle
            end
            S7_SYNC: begin
                // Synchronization logic can be added here
                next_state = S0_IDLE; // Go back to idle state after processing
                read_en = 3'b000; // Disable read for all channels
                O_data_available = 1; // Data is available after processing
            end
            default: begin
                next_state = S0_IDLE; // Default to idle state
                read_en = 3'b000; // Disable read for all channels
                O_data_available = 0; // No data available in default state
            end
        endcase
    end



endmodule