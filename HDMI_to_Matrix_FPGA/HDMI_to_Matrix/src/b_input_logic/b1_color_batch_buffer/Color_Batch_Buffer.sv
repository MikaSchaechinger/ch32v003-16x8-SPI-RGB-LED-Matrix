module Color_Batch_Buffer #(
    parameter int BATCH_SIZE = 8
)(
    input logic I_rgb_clk,
    input logic I_rst_n,
    input logic I_flush,    // Flush signal fills the remaining buffer with 0s and switches the buffer

    input logic [7:0] I_color,
    input logic I_color_valid,

    output logic O_batch_ready,
    output logic O_batch_clk_out,
    output logic [8*BATCH_SIZE-1:0] O_batch_color
);


    // Lokale Parameter
    localparam int WRITE_POINTER_WIDTH = $clog2(BATCH_SIZE)+1;


    // Internal double Buffer
    logic [7:0] color_buffer [1:0][BATCH_SIZE-1:0];  // Two buffers with BATCH_SIZE colors each
    // control register
    logic active_buffer;
    logic [WRITE_POINTER_WIDTH-1:0] write_ptr;
    logic output_valid;


    // Flush edge detection
    logic flush_d, flush_posedge;
    always_ff @(posedge I_rgb_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            flush_d <= 1'b0;
        end else begin
            flush_d <= I_flush;
        end
    end

    assign flush_posedge = ~flush_d & I_flush; // Detect the posedge of the flush signal



    // Write logic
    always_ff @(posedge I_rgb_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            active_buffer <= 0;
            write_ptr <= 0; //BATCH_SIZE - 1;  // Start at the end of the buffer
            output_valid <= 0;
        end else begin
            if (I_color_valid) begin
                color_buffer[active_buffer][write_ptr] <= I_color;
                
                if (write_ptr == BATCH_SIZE - 1) begin
                    write_ptr <= 0;
                    output_valid <= 1;
                    active_buffer <= ~active_buffer;  // Switch to the other buffer
                end else begin
                    write_ptr <= write_ptr + 1;
                    output_valid <= 0;
                end
            end else if (flush_posedge && write_ptr != 0) begin
                // Fill the remaining buffer with 0s and switch the buffer
                for (int i = write_ptr; i < BATCH_SIZE; i++) begin
                    color_buffer[active_buffer][i] <= 8'h00; // Fill with 0s
                end
                write_ptr <= 0;
                output_valid <= 1;
                active_buffer <= ~active_buffer;  // Switch to the other buffer
            end else begin
                output_valid <= 0;
            end
        end
    end

    // Output logic
    assign O_batch_ready = output_valid && (write_ptr == 0);
    assign O_batch_clk_out = ~O_batch_ready; // Invert the batch ready signal for the output clock

    always_comb begin
        for (int i = 0; i < BATCH_SIZE; i++) begin
            O_batch_color[i*8 +: 8] = color_buffer[~active_buffer][i];
        end
    end

    // Debugging
    logic [8*BATCH_SIZE-1:0] color_buffer_flat;
    always_comb begin
        for (int i = 0; i < BATCH_SIZE; i++) begin
            color_buffer_flat[i*8 +: 8] = color_buffer[active_buffer][i];
        end
    end


endmodule