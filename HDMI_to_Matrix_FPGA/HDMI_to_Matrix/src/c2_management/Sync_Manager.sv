module Sync_Manager #(
    parameter int MAX_WIDTH = 1920,
    parameter int MAX_HEIGHT = 1080,
    parameter int DELAY = 0
)(
    input  logic                          I_rst_n,
    input  logic                          I_rgb_clk,
    input  logic                          I_rgb_de,
    input  logic                          I_rgb_hsync,
    input  logic                          I_rgb_vsync,

    output logic [$clog2(MAX_WIDTH)-1:0]  O_image_width,
    output logic [$clog2(MAX_HEIGHT)-1:0] O_image_height,
    output logic                          O_width_valid,
    output logic                          O_height_valid,

    output logic                          O_new_row,
    output logic                          O_new_frame,
    output logic                          O_image_valid
);

    logic frame_started;

    // === Neg Edge detection hsync/vsync ===
    logic rgb_hsync_d, rgb_vsync_d;

    always_ff @(posedge I_rgb_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            rgb_hsync_d <= 1'b0;
            rgb_vsync_d <= 1'b0;
        end else begin
            rgb_hsync_d <= I_rgb_hsync;
            rgb_vsync_d <= I_rgb_vsync;
        end
    end


    logic new_row_imm, new_frame_imm, new_row_delay, new_frame_delay;
    assign new_row_imm   = rgb_hsync_d & ~I_rgb_hsync;  // fallende Flanke
    assign new_frame_imm = rgb_vsync_d & ~I_rgb_vsync;  // fallende Flanke

    // === Delay for Pipeline Sync ===

    logic rgb_de;
    generate
        if (DELAY == 0) begin
            assign new_row_delay   = new_row_imm;
            assign new_frame_delay = new_frame_imm;
            assign rgb_de = I_rgb_de;
        end else if (DELAY == 1) begin
            logic rgb_de_internal_delay;

            always_ff @(posedge I_rgb_clk or negedge I_rst_n) begin
                if (!I_rst_n) begin
                    new_row_delay   <= 1'b0;
                    new_frame_delay <= 1'b0;
                    rgb_de_internal_delay <= 1'b0;
                end else begin
                    new_row_delay   <= new_row_imm;
                    new_frame_delay <= new_frame_imm;
                    rgb_de_internal_delay <= I_rgb_de;
                end
            end

            assign rgb_de = rgb_de_internal_delay;
        end else begin
            logic [DELAY-1:0] new_row_pipeline, new_frame_pipeline, rgb_de_internal_delay;

            always_ff @(posedge I_rgb_clk or negedge I_rst_n) begin
                if (!I_rst_n) begin
                    new_row_pipeline   <= '0;
                    new_frame_pipeline <= '0;
                    rgb_de_internal_delay <= '0;
                end else begin
                    new_row_pipeline   <= {new_row_pipeline[DELAY-2:0], new_row_imm};
                    new_frame_pipeline <= {new_frame_pipeline[DELAY-2:0], new_frame_imm};
                    rgb_de_internal_delay <= {rgb_de_internal_delay[DELAY-2:0], I_rgb_de};
                end
            end

            assign new_row_delay   = new_row_pipeline[DELAY-1];
            assign new_frame_delay = new_frame_pipeline[DELAY-1];
            assign rgb_de = rgb_de_internal_delay[DELAY-1];
        end
    endgenerate

    assign O_new_row   = new_row_delay & frame_started;
    assign O_new_frame = new_frame_delay & frame_started;
    assign O_image_valid = O_new_row | O_new_frame;
    // === Image width and height detection ===



    logic [$clog2(MAX_WIDTH)-1:0]  width_counter;
    logic [$clog2(MAX_HEIGHT)-1:0] height_counter;

    always_ff @(posedge I_rgb_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            width_counter  <= '0;
            height_counter <= '0;
            O_width_valid  <= 1'b0;
            O_height_valid <= 1'b0;
            O_image_width  <= '0;
            O_image_height <= '0;
            frame_started <= 1'b0;
        end else begin
            if (frame_started) begin
                if (new_frame_delay) begin
                    height_counter <= '0;
                    if (height_counter != 0) begin
                        O_image_height <= height_counter;
                        O_height_valid <= 1'b1;
                    end
                end if (new_row_delay) begin
                    width_counter <= (I_rgb_de) ? 1 : 0;
                    if (width_counter != 0) begin
                        O_width_valid  <= 1'b1;
                        height_counter <= height_counter + 1;
                        O_image_width  <= width_counter;
                    end
                end else if (rgb_de) begin
                    width_counter <= width_counter + 1;     
                end
            end else begin
                if (new_frame_delay) begin
                    frame_started <= 1'b1;
                end
            end
        end
    end



endmodule