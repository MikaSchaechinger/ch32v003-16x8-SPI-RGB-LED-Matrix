
// Raspberry Pi custom Resolution: https://stackoverflow.com/questions/52335356/custom-resolution-on-raspberry-pi


module LED_Matrix_top(
    input wire clk,
    input wire [1:0] btn,
    
    input wire I_tmds_clk_p,
    input wire I_tmds_clk_n,
    input wire [2:0] I_tmds_data_p,
    input wire [2:0] I_tmds_data_n, 

    output wire spi_clk,
    output wire [ROW_NUMBER-1:0] spi_mosi,
    output wire shift_clk,
    output wire shift_ser,
    output wire shift_stcp,
    output wire shift_en,
    output reg [5:0] led
); 
 
localparam ROW_NUMBER = 3;

    //============== Create test LED 0 blink ==============


    reg [23:0] counter = 24'b0;     //24-Bit Counter

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    always @(posedge clk) begin
        if (btn[0]) begin
            led <= counter[23:18];
        end else begin
            led <= 6'b0;
        end
    end



endmodule




