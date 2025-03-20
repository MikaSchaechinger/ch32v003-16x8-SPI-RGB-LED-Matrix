
// Raspberry Pi custom Resolution: https://stackoverflow.com/questions/52335356/custom-resolution-on-raspberry-pi


module LED_Matrix_top(
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
    localparam CHANNEL_NUMBER = 3;
    localparam SPI_SIZE = 8;

    //============== Create test LED 0 blink ==============





    //============== Type Definitions ===============

    typedef enum logic [2:0] { 
        S0_STARTUP,
        S1_NEW_IMAGE,
        S2_START_OUTPUT
    } state_t;

    //============== Local Signals ===============
    reg rst = 0;
    wire tx_finish;

    reg [SPI_SIZE-1:0] data = 0;
    reg [SPI_SIZE-1:0] data_in [CHANNEL_NUMBER-1:0];

    reg new_image;
    reg new_column;
    reg next_data;
    
    state_t state = S0_STARTUP;
    state_t next_state = S0_STARTUP;

    reg [8:0] counter = 0;

    // ============= Logic =============

    always_comb begin
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            data_in[i] = data;
        end
    end

    // Button controls data
    always @(posedge clk) begin
        if (btn[1]) begin
            data <= 8'hFF;
        end else begin
            data <= 8'h00;
        end
    end

    always_ff @(posedge clk) begin
        state <= next_state;
        new_column = 0;

        if (next_state == S1_NEW_IMAGE) begin
            counter <= 0;
            new_image = 1;
        end else if (next_state == S2_START_OUTPUT) begin
            new_image = 0;
            if (tx_finish) begin
                if (!next_data) begin
                    next_data = 1;
                    counter <= 8'(counter + 1);
                end
            end else begin
                next_data = 0;
            end
        end
    end

    always_comb begin
        case (state)
            S0_STARTUP: begin
                rst = 1;
                next_state = S1_NEW_IMAGE;
            end
            S1_NEW_IMAGE: begin
                rst = 0;
                if (tx_finish==0)begin
                    next_state = S2_START_OUTPUT;
                end else begin
                    next_state = S1_NEW_IMAGE;
                end
            end
            S2_START_OUTPUT: begin
                rst = 0;
                if (counter == 383) begin
                    next_state = S1_NEW_IMAGE;
                end else begin
                    next_state = S2_START_OUTPUT;
                end
            end
            default: begin
                rst = 1;
                next_state = S0_STARTUP;
            end
        endcase
    end



    output_module #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .SPI_SIZE(SPI_SIZE),
        .MSB_FIRST(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .start_first_column(new_image),
        .start_next_column(new_column),
        .next_data(next_data),
        .extra_bit(1'b0),
        .tx_finish(tx_finish),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .ser_clk(shift_clk),
        .ser_data(shift_ser),
        .ser_stcp(shift_stcp),
        .ser_n_enable(shift_en)
    );


endmodule




