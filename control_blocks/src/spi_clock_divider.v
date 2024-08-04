

module spi_clock_divider(
    input wire start,
    input wire rst,
    input wire clk,
    input wire [7:0] clk_div,
    output wire spi_clk,
    output wire active
);

// State signals

reg [7:0] clk_div_counter = 0;  // counts clock cycles for clock divider
reg spi_clk_internal = 0;  // divided clock
reg active_internal = 0;


reg r_clk_internal=0;
wire w_xor_clk_internal = (r_clk_internal ^ clk);


always @(posedge w_xor_clk_internal) begin
    r_clk_internal <= ~r_clk_internal;
    if (rst) begin
        active_internal <= 1'b0;
        clk_div_counter <= 8'd0;
        spi_clk_internal <= 1'b0;
    end else begin // clk
        if (active_internal == 0 && start == 1) begin
            active_internal <= 1'b1;
            clk_div_counter <= 8'd0;
            spi_clk_internal <= 1'b1;
        end else if (active_internal) begin
            if (clk_div_counter >= clk_div) begin
                clk_div_counter <= 8'd0;
                spi_clk_internal <= ~spi_clk_internal;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end
end
 


assign spi_clk = spi_clk_internal;
assign active = active_internal;


endmodule



