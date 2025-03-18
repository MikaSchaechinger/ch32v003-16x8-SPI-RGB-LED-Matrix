module nspi_tx #(
    parameter CHANNEL_NUMBER = 3,
    parameter SPI_SIZE = 8,  // 8 or 16
    parameter MSB_FIRST = 1 // 1 for MSB first, 0 for LSB first
)(
    input wire clk,
    input wire rst,
    input wire start_tx, // Start transmission at rising edge
    output reg tx_finish = 0, // Low during transmission

    input wire [SPI_SIZE-1:0] data_in [CHANNEL_NUMBER-1:0],
    output reg spi_clk,
    output reg [CHANNEL_NUMBER-1:0] spi_mosi
);

    //============== Type Definitions ===============

    typedef enum logic [1:0] { IDLE, STARTING, TRANSMIT } state_t;


    //============== Internal Signals ===============

    reg start_tx_internal = 0;
    reg [SPI_SIZE-1:0] data_in_reg [CHANNEL_NUMBER-1:0];
    state_t state = IDLE;
    state_t next_state = IDLE;
    localparam int COUNTER_WIDTH = $clog2(SPI_SIZE+1);
    reg [COUNTER_WIDTH-1:0] counter = 0;
    reg overflow_finish = 0;


    //=============== Code Logic ===============

    always @(posedge start_tx or posedge overflow_finish) begin
        if (overflow_finish) begin
            start_tx_internal <= 0;
        end else if (start_tx) begin
            counter <= 0;
            start_tx_internal <= 1;
        end
    end

    always @(posedge start_tx_internal) begin
        if (MSB_FIRST) begin
            for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                for (int j = 0; j < SPI_SIZE; j++) begin
                    data_in_reg[i][j] <= data_in[i][SPI_SIZE-j-1];
                end
            end
        end else begin
            for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                data_in_reg[i] <= data_in[i];
            end
        end
    end


    
    // assign tx_finish = ~start_tx_internal;
    always @(posedge start_tx_internal or posedge clk) begin
        if (start_tx_internal) begin
            tx_finish <= 0;
        end else if (state == IDLE) begin
            tx_finish <= 1;
        end
    end


    // State Machine Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;

        end
    end

    always_comb begin
        case (state)
            IDLE: begin
                if (start_tx_internal) begin
                    next_state = STARTING;
                end else begin
                    next_state = IDLE;
                end

                overflow_finish = 0;
            end
            STARTING: begin
                next_state = TRANSMIT;
                overflow_finish = 0;
            end
            TRANSMIT: begin
                if (counter == SPI_SIZE) begin
                    next_state = IDLE;
                    overflow_finish = 1;
                end else begin
                    next_state = TRANSMIT;
                    overflow_finish = overflow_finish;
                end

            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    


    // SPI Logic
    always_ff @(posedge clk or negedge clk) begin

        if (state == IDLE) begin
            spi_clk <= 0;
            spi_mosi <= 0;
        end else if (state == STARTING) begin
            spi_clk <= 0;
            for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                spi_mosi[i] <= data_in_reg[i][counter];
            end
        end else if (state == TRANSMIT) begin
            if(clk == 1) begin
                // update MOSI and reset SPI_CLK
                spi_clk <= 0;
                if (counter < SPI_SIZE) begin
                    for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                        spi_mosi[i] <= data_in_reg[i][counter];
                    end
                end else begin
                    spi_mosi <= 0;
                end

            end
            else if (clk == 0) begin
                // set SPI_CLK = 1
                spi_clk <= 1;
                counter <= counter + 1;
            end
        end
    end



endmodule