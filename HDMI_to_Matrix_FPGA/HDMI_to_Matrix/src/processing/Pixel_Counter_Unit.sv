// PixelCounterUnit: Dynamische Auflösungserkennung mit FSM-Zähleranbindung
module Pixel_Counter_Unit #(
    parameter int MAX_PIXELS_PER_ROW = 1920,
    parameter int MAX_ROWS_PER_FRAME = 1080
)(
    input  logic clk,
    input  logic rst,

    input  logic vsync,
    input  logic hsync,
    input  logic rgb_de,
    input  logic pixel_accepted,     // 1 Takt High wenn 1 Pixelblock verarbeitet wurde

    output logic end_of_row,
    output logic end_of_panel,
    output logic end_of_frame,
    output logic [$clog2(MAX_PIXELS_PER_ROW):0]  pixel_count,
    output logic [$clog2(MAX_ROWS_PER_FRAME):0]  row_count,
    output logic [$clog2(MAX_ROWS_PER_FRAME):0]  frame_pixel_lines
);

    // Flanken erkennen
    logic vsync_d, hsync_d;
    logic vsync_rising, hsync_rising;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            vsync_d <= 0;
            hsync_d <= 0;
        end else begin
            vsync_d <= vsync;
            hsync_d <= hsync;
        end
    end

    assign vsync_rising = vsync & ~vsync_d;
    assign hsync_rising = hsync & ~hsync_d;

    // Dynamische Auflösungserkennung
    logic [$clog2(MAX_PIXELS_PER_ROW):0] current_line_pixel_count;
    logic [$clog2(MAX_ROWS_PER_FRAME):0] current_frame_line_count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst || vsync_rising) begin
            current_line_pixel_count <= 0;
            current_frame_line_count <= 0;
        end else begin
            if (rgb_de) begin
                current_line_pixel_count <= current_line_pixel_count + 1;
            end
            if (hsync_rising && current_line_pixel_count != 0) begin
                current_frame_line_count <= current_frame_line_count + 1;
                current_line_pixel_count <= 0;
            end
        end
    end

    assign frame_pixel_lines = current_frame_line_count;

    // Pixel- und Zeilenzähler für FSM-Logik
    always_ff @(posedge clk or posedge rst) begin
        if (rst || vsync_rising) begin
            pixel_count <= 0;
            row_count   <= 0;
        end else begin
            if (pixel_accepted) begin
                pixel_count <= pixel_count + 1;
                if (pixel_count == current_line_pixel_count - 1) begin
                    pixel_count <= 0;
                    row_count <= row_count + 1;
                end
            end
        end
    end

    assign end_of_row   = pixel_accepted && (pixel_count == current_line_pixel_count - 1);
    assign end_of_panel = 0; // nicht mehr gebraucht oder extern berechnet
    assign end_of_frame = vsync_rising;

endmodule
