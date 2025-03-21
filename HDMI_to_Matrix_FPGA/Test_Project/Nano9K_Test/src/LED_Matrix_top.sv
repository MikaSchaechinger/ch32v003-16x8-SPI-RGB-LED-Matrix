
// Raspberry Pi custom Resolution: https://stackoverflow.com/questions/52335356/custom-resolution-on-raspberry-pi


module LED_Matrix_top #(
    parameter CHANNEL_NUMBER = 3,
    parameter BYTES_PER_MATRIX = 8*16*3,
    parameter DIV_FACTOR = 100 // Slow Clock Divider
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

    typedef enum logic [1:0] { 
        S0_STARTUP,
        S1_NEW_IMAGE,
        S2_NEXT_DATA,
        S3_START_OUTPUT
    } state_t;

    //============== Local Signals ===============
    wire rst;
    wire tx_finish;

    reg [SPI_SIZE-1:0] data = 0;
    reg [SPI_SIZE-1:0] data_in [CHANNEL_NUMBER-1:0];

    reg new_image;
    reg new_column;
    reg next_data;
    
    state_t state = S0_STARTUP;
    state_t next_state = S0_STARTUP;

    
    localparam int COUNTER_WIDTH = $clog2(BYTES_PER_MATRIX+1);
    reg [COUNTER_WIDTH-1:0] counter = 0;


    // ============= Logic =============

    // always_comb begin
    //     for (int i = 0; i < CHANNEL_NUMBER; i++) begin
    //         data_in[i] = data;
    //     end
    // end


    always_ff @(posedge rst or posedge slow_clk) begin
        if (rst) begin
            state <= S0_STARTUP;
            new_column = 0;
            new_image = 0;
            next_data = 0;
            data_in[0] = 8'h01;
            data_in[1] = 8'h00;
            data_in[2] = 8'h00;
        end else begin
            state <= next_state;
            new_column = 0;

            if (next_state == S1_NEW_IMAGE) begin
                counter <= 0;
                new_image = 1;
            end else if (next_state == S2_NEXT_DATA) begin
                new_image = 0;
                if (tx_finish) begin
                    if (next_data == 0) begin
                        counter <= COUNTER_WIDTH'(counter + 1);
                        if (counter == BYTES_PER_MATRIX-1) begin
                            next_data = 0;
                        end else begin
                            next_data = 1;
                            if (counter < 8*16) begin
                                data_in[0] <= 8'hFF;
                                data_in[1] <= 8'h00;
                                data_in[2] <= 8'h00;
                            end else begin
                                data_in[0] <= 8'h00;
                                data_in[1] <= 8'hFF;
                                data_in[2] <= 8'h00;
                            end
                        end
                    end
                end
            end else if (next_state == S3_START_OUTPUT) begin
                new_image = 0;
                next_data = 0;


                // new_image = 0;
                // if (tx_finish) begin
                //     if (!next_data) begin
                //         next_data = 1;
                //         counter <= 8'(counter + 1);
                //     end
                // end else begin
                //     next_data = 0;
                // end
            end
        end
    end

    always_comb begin
        if (rst) begin
            next_state = S0_STARTUP;
        end else begin
            case (state)
                S0_STARTUP: begin
                    next_state = S1_NEW_IMAGE;
                    if (tx_finish) begin
                        next_state = S1_NEW_IMAGE;
                    end else begin
                        next_state = S0_STARTUP;
                    end
                end
                S1_NEW_IMAGE: begin
                    if (tx_finish==0)begin
                        next_state = S3_START_OUTPUT;
                    end else begin
                        next_state = S1_NEW_IMAGE;
                    end
                end
                S2_NEXT_DATA: begin
                    if (tx_finish==0)begin
                        if (counter == BYTES_PER_MATRIX) begin
                            next_state = S1_NEW_IMAGE;
                        end else begin
                            next_state = S3_START_OUTPUT;
                        end
                    end else begin
                        next_state = S2_NEXT_DATA;
                    end
                end
                S3_START_OUTPUT: begin
                    if (counter == BYTES_PER_MATRIX) begin
                        next_state = S1_NEW_IMAGE;
                    end else begin
                        if (tx_finish) begin
                            if (counter == BYTES_PER_MATRIX-1) begin
                                next_state = S1_NEW_IMAGE;
                            end else begin
                                next_state = S2_NEXT_DATA;
                            end
                        end else begin
                            next_state = S3_START_OUTPUT;
                        end
                    end
                end
                default: begin
                    next_state = S0_STARTUP;
                end
            endcase
        end
    end


    output_module #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .SPI_SIZE(SPI_SIZE),
        .MSB_FIRST(1)
    ) output_module_inst (
        .clk(slow_clk),
        .rst(rst),
        .data_in(data_in),
        .new_image(new_image),
        .new_column(new_column),
        .next_data(next_data),
        .extra_bit(1'b1),
        .tx_finish(tx_finish),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .ser_clk(shift_clk),
        .ser_data(shift_ser),
        .ser_stcp(shift_stcp),
        .ser_n_enable(shift_en)
    );


    assign led[0] = !new_image;
    assign led[1] = !new_column;
    assign led[2] = !next_data;
    assign led[3] = !tx_finish;
    //assign led[4] = !foo;
    assign led[5] = !spi_clk;
    assign rst = !btn[0];





endmodule




