module Info_Buffer #(
    parameter int MAX_WIDTH = 1920,
    parameter int MAX_HEIGHT = 1080,
)(
    input  logic                        I_rst_n,
    input  logic                        I_clk,
    input  logic                        I_swap_trigger,             // z. B. bei frame_complete
    
    input  logic [$clog2(MAX_WIDTH)-1:0] I_image_width,
    input  logic [$clog2(MAX_HEIGHT)-1:0] I_image_height,
    input  logic                        I_image_valid,
    input  logic                        I_next_column,
    input  logic                        I_next_image,

    output logic [$clog2(MAX_WIDTH)-1:0] O_image_width,
    output logic [$clog2(MAX_HEIGHT)-1:0] O_image_height,
    output logic                        O_image_valid,
    output logic                        O_next_column,
    output logic                        O_next_image
);

    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            O_image_width  <= 0;
            O_image_height <= 0;
            O_image_valid  <= 1'b0;
            O_next_column  <= 1'b0;
            O_next_image   <= 1'b0;
        end else if (I_swap_trigger) begin
            O_image_width  <= I_image_width;
            O_image_height <= I_image_height;
            O_image_valid  <= I_image_valid;
            O_next_column  <= I_next_column;
            O_next_image   <= I_next_image;
        end
    end


endmodule