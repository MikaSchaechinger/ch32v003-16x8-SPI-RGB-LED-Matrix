module rgb_to_bram(
    input wire clk,             // fast clk
    input wire [7:0] rgb_r_o,
    input wire [7:0] rgb_g_o,
    input wire [7:0] rgb_b_o,
    // maybe de input

    // interface to bram: data, addr, write
    output wire write,
    output wire [7:0] addr,     // width needs to be checked
    output [7:0] bram_data      // width needs to be checked
);
