module nspi_tx #(
    parameter CHANNEL_NUMBER = 3,
    parameter SPI_SIZE = 8,  // 8 or 16
    parameter MSB_FIRST = 1 // 1 for MSB first, 0 for LSB first
)(
    input logic clk,
    input logic rst,
    input logic start_tx, // Start transmission at rising edge
    output logic tx_finish, // Low during transmission

    input logic [SPI_SIZE*CHANNEL_NUMBER-1:0] I_data_flat,
    output logic spi_clk,
    output logic [CHANNEL_NUMBER-1:0] spi_mosi
);

    //============== Type Definitions ===============

    typedef enum logic [1:0] { IDLE, STARTING, TRANSMIT } state_t;
    typedef enum logic {CLK_NEXT, MOSI_NEXT} next_t;

    //============== Internal Signals ===============

    logic start_tx_internal = 0;
    logic [SPI_SIZE-1:0] data_in [CHANNEL_NUMBER-1:0]; 
    logic [SPI_SIZE-1:0] data_in_reg [CHANNEL_NUMBER-1:0];
    state_t state = IDLE;
    state_t next_state = IDLE;
    localparam int COUNTER_WIDTH = $clog2(SPI_SIZE+1);
    logic [COUNTER_WIDTH-1:0] counter = 0;

    logic counter_overflow_flag = 0;

    next_t next = MOSI_NEXT;

    //=============== Code Logic ===============

    // Distribute I_data_flat to data_in
    always_comb begin
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            data_in[i] = I_data_flat[i*SPI_SIZE +: SPI_SIZE];
        end
    end


    always @(posedge rst or posedge clk) begin
        if (rst) begin
            start_tx_internal <= 0;
        end else begin
            if (counter_overflow_flag) begin
                start_tx_internal <= 0;
            end else if (start_tx) begin
                start_tx_internal <= 1;
            end
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
    always @(posedge rst or posedge clk) begin
        if (rst) begin
            tx_finish <= 0;
        end else begin
            if (next_state == IDLE) begin
                tx_finish <= 1;
            end else begin
                tx_finish <= 0;
            end
        end
    end





    // counter control
    always_ff @(posedge rst or posedge clk) begin
        if (rst) begin
            counter <= 0;
            counter_overflow_flag <= 0;
        end else begin
            if (next_state == TRANSMIT) begin
                if (next == CLK_NEXT) begin
                    counter <= COUNTER_WIDTH'(counter + 1);
                end
                if (counter + 1 == SPI_SIZE) begin
                    counter_overflow_flag <= 1;
                end else begin
                    counter_overflow_flag <= 0;
                end
            end else begin
                counter <= 0;
                counter_overflow_flag <= 0;
            end
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
            IDLE: begin     // 0
                if (start_tx_internal) begin
                    next_state = STARTING;
                end else begin
                    next_state = IDLE;
                end
            end
            STARTING: begin     // 1
                next_state = TRANSMIT;
            end
            TRANSMIT: begin     // 2
                if (counter_overflow_flag) begin
                    next_state = IDLE;
                end else begin
                    next_state = TRANSMIT;
                end

            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    


    // SPI Logic
    


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            spi_clk <= 0;
            spi_mosi <= 0;
            next <= MOSI_NEXT;
        end else begin
            if (state == IDLE) begin
                spi_clk <= 0;
                spi_mosi <= 0;
            end else if (state == STARTING) begin
                spi_clk <= 0;
                for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                    spi_mosi[i] <= data_in_reg[i][counter];
                end
            end else if (state == TRANSMIT) begin
                if(next == MOSI_NEXT) begin
                    // update MOSI and reset SPI_CLK
                    next <= CLK_NEXT;
                    spi_clk <= 0;
                    if (counter < SPI_SIZE) begin
                        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
                            spi_mosi[i] <= data_in_reg[i][counter];
                        end
                    end else begin
                        spi_mosi <= 0;
                    end

                end
                else if (next == CLK_NEXT) begin
                    next <= MOSI_NEXT;
                    spi_clk <= 1;
                    spi_mosi <= spi_mosi;
                end
            end else begin
                spi_clk <= 0;
                spi_mosi <= 0;
            end
        end
    end



endmodule