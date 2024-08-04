/*
*   This module can send n mosi channels in parallel with only one clock line.
*   This module has an input Buffer with n channels of 16 bits each, so new data can be loaded in parallel. With the start_transmit signal, the module will save data_in in a buffer and start transmitting it in the next clock cycle.
*   The module starts directly transmitting again (with the new data from data_in), when start_transmit is high again.
*/


module spi_tx_n_mosi #(
    parameter channels = 3
)
(
    input wire clk,
    input wire rst,
    input wire [7:0] spi_clk_divider,
    // input array of n channels with 16 bits each
    input wire [15:0] data_in [0:channels-1],
    input wire start_transmit,

    output wire transmit_finish,
    output reg spi_clk_out,
    output reg [0:channels-1] mosi_out
);


    localparam IDLE = 0;
    localparam BUFFERING = 1;
    localparam TRANSMIT = 2;




    reg [1:0] current_state = IDLE;
    reg transmit_finish_internal = 0;

    // State machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end 
        else begin
            case (current_state)
                IDLE: begin
                    if (start_transmit) begin
                        current_state <= BUFFERING;
                    end
                end
                BUFFERING: begin
                    current_state <= TRANSMIT;
                end
                TRANSMIT: begin
                    if (transmit_finish_internal) begin
                        current_state <= IDLE;
                    end
                end
            endcase
        end
    end


    
    // input_buffer
    reg [channels-1:0][15:0] input_buffer = 0;
    reg in_transmit_state = 0;

    // State machine output logic
    always_comb begin
        case (current_state)
            IDLE: begin
                in_transmit_state = 0;
            end
            BUFFERING: begin
                in_transmit_state = 0;
                for (int i = 0; i < channels; i++) begin
                    input_buffer[i] = data_in[i];
                end
            end
            TRANSMIT: begin
                in_transmit_state = 1;
            end
        endcase
    end




    wire spi_clk_internal;

    // Clock divider for SPI clock
    spi_clock_divider spi_clk_divider_inst(
        .start(in_transmit_state),
        .clk(clk),
        .rst(rst),
        .clk_div(spi_clk_divider),
        .spi_clk(spi_clk_internal),
        .active()
    );





    // Transmit registers and wires
    // 4 bit counter for the transmit
    reg [3:0] transmit_counter = 0;

    // pos and neg edge clk triggered process
    reg clk_reg = 0;
    wire w_xor_clk = (clk_reg ^ spi_clk_internal);

    // Transmitt controller
    always_ff @(posedge w_xor_clk or posedge rst) begin
        clk_reg <= ~clk_reg;

        if (rst) begin
            spi_clk_out <= 0;



        // the out clock is inverted to the internal spi clock, so that the transmit starts with a low clock
        end 
        else if (current_state == TRANSMIT && transmit_finish_internal == 0) begin
            // Transmit data
            if (spi_clk_internal == 0) begin
                spi_clk_out <= 0;       // inverted
                if (transmit_counter == 15) begin
                    transmit_finish_internal <= 1;
                    transmit_counter <= 0;
                end
                else begin
                    transmit_finish_internal <= 0;
                    transmit_counter <= transmit_counter + 1;
                end
            
            end 
            else begin
                spi_clk_out <= 1;



            end
        end if (current_state != TRANSMIT) begin
            spi_clk_out <= 0;
            transmit_finish_internal <= 0;
            transmit_counter <= 0;
        end
        // else begin
        //     spi_clk_out <= 0;
        //     transmit_finish_internal <= 0;
        //     transmit_counter <= 0;
        // end
    end


    generate 
        genvar i;
        for (i = 0; i < channels; i++) begin : gen_mosi_out
            assign mosi_out[i] = input_buffer[i][transmit_counter] & ~transmit_finish_internal & ~rst;
        end
    endgenerate

    assign transmit_finish = transmit_finish_internal;



endmodule