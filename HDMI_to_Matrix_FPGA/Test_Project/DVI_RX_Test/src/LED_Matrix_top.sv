
// Raspberry Pi custom Resolution: https://stackoverflow.com/questions/52335356/custom-resolution-on-raspberry-pi


module LED_Matrix_top #(
    parameter CHANNEL_NUMBER = 3,
    parameter BYTES_PER_MATRIX = 8*16*3,
    parameter DIV_FACTOR = 1000 // Slow Clock Divider
)(
    input wire clk,
    input wire [1:0] btn,
    
    input wire I_tmds_clk_p,
    input wire I_tmds_clk_n,
    input wire [2:0] I_tmds_data_p,
    input wire [2:0] I_tmds_data_n, 

    output wire spi_clk,
    output wire [CHANNEL_NUMBER-1:0] spi_mosi,
    output wire shift_clk,
    output wire shift_ser,
    output wire shift_stcp,
    output wire shift_en,
    output reg [5:0] led
); 
    localparam SPI_SIZE = 8;


    //============== Slow Clock ==============
    reg [31:0] slow_counter = 0;
    reg slow_clk = 0;

    always @(posedge clk) begin
        if (slow_counter == (DIV_FACTOR/2 - 1)) begin
            slow_clk <= ~slow_clk; // Flip-Flop für 50% Duty Cycle
            slow_counter <= 0;
        end else begin
            slow_counter <= slow_counter + 1;
        end
    end

    //============== Type Definitions ===============




endmodule




