module Info_Buffer #(
    parameter int MAX_WIDTH = 1920,
    parameter int MAX_HEIGHT = 1080
)(
    input  logic                        I_rst_n,
    input  logic                        I_clk,
    input  logic                        I_swap_trigger,             // z. B. bei frame_complete
    
    input  logic [$clog2(MAX_WIDTH)-1:0] I_image_width,
    input  logic [$clog2(MAX_HEIGHT)-1:0] I_image_height,
    input  logic                        I_image_valid,
    input  logic                        I_hs_detected,
    input  logic                        I_vs_detected,

    output logic [$clog2(MAX_WIDTH)-1:0] O_image_width,
    output logic [$clog2(MAX_HEIGHT)-1:0] O_image_height,
    output logic                        O_image_valid,
    output logic                        O_hs_detected,
    output logic                        O_vs_detected
);

    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            O_image_width  <= 0;
            O_image_height <= 0;
            O_image_valid  <= 1'b0;
            O_hs_detected  <= 1'b0;
            O_vs_detected   <= 1'b0;
        end else if (I_swap_trigger) begin
            O_image_width  <= I_image_width;
            O_image_height <= I_image_height;
            O_image_valid  <= I_image_valid;
            O_hs_detected  <= I_hs_detected;
            O_vs_detected   <= I_vs_detected;
        end
    end


endmodule