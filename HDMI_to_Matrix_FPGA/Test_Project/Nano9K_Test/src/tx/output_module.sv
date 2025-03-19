module output_module #(
    parameter CHANNEL_NUMBER = 3,
    parameter SPI_SIZE = 8,
    parameter MSB_FIRST = 1
)(
    input wire clk,
    input wire rst,

    input wire [SPI_SIZE-1:0] data_in [CHANNEL_NUMBER-1:0],
    input wire start_first_column,
    input wire start_next_column,
    input wire next_data,
    input wire extra_bit,

    output reg tx_finish,

    output wire spi_clk,
    output wire [CHANNEL_NUMBER-1:0] spi_mosi,

    output wire ser_clk,
    output wire ser_data,
    output wire ser_stcp,
    output wire ser_n_enable
);


    //============== Type Definitions ===============
    typedef enum logic [2:0] { 
        S0_IDLE, 
        S10_SEL_FIRST, 
        S11_SEL_NEXT, 
        S2_WAIT_FOR_READY,
        S3_START_SPI_TX,
        S4_WAIT_FOR_SPI_TX_FINISH
    } state_t;

    //============== Internal Signals =================
    // Connection to Moduls

    state_t state = S0_IDLE;
    state_t next_state = S0_IDLE;
    wire column_select_ready;
    wire spi_tx_finish;
    reg spi_start_tx = 0;
    reg select_first = 0;
    reg select_next = 0;

    //=============== Code Logic ===============

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0_IDLE;
        end else if (clk) begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            S0_IDLE: begin
                if (start_first_column) begin
                    next_state = S10_SEL_FIRST;
                end else if (start_next_column) begin
                    next_state = S11_SEL_NEXT;
                end else if (next_data) begin
                    next_state = S3_START_SPI_TX;
                end else begin
                    next_state = S0_IDLE;
                end
                tx_finish = 1;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
            S10_SEL_FIRST: begin
                if (column_select_ready == 0) begin
                    next_state = S2_WAIT_FOR_READY;
                end else begin
                    next_state = S10_SEL_FIRST;
                end
                tx_finish = 0;
                select_first = 1;
                select_next = 0;
                spi_start_tx = 0;
            end
            S11_SEL_NEXT: begin
                if (column_select_ready == 0) begin
                    next_state = S2_WAIT_FOR_READY;
                end else begin
                    next_state = S11_SEL_NEXT;
                end
                tx_finish = 0;
                select_first = 0;
                select_next = 1;
                spi_start_tx = 0;
            end
            S2_WAIT_FOR_READY: begin
                if (column_select_ready==1) begin
                    next_state = S3_START_SPI_TX;
                end else begin
                    next_state = S2_WAIT_FOR_READY;
                end
                tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
            S3_START_SPI_TX: begin
                if (spi_tx_finish == 0) begin
                    next_state = S4_WAIT_FOR_SPI_TX_FINISH;
                end else begin
                    next_state = S3_START_SPI_TX;
                end
                tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 1;
            end
            S4_WAIT_FOR_SPI_TX_FINISH: begin
                if (spi_tx_finish) begin
                    next_state = S0_IDLE;
                end else begin
                    next_state = S4_WAIT_FOR_SPI_TX_FINISH;
                end
                tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
            default: begin
                next_state = S0_IDLE;
                tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
        endcase
    end


    nspi_tx #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .SPI_SIZE(SPI_SIZE),
        .MSB_FIRST(MSB_FIRST)
    ) spi_tx (
        .clk(clk),
        .rst(rst),
        .start_tx(spi_start_tx),
        .tx_finish(spi_tx_finish),
        .data_in(data_in),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi)
    );


    column_select cs (
        .clk(clk),
        .rst(rst),
        .select_first(select_first),
        .select_next(select_next),
        .extra_bit(extra_bit),
        .ready(column_select_ready),
        .ser_clk(ser_clk),
        .ser_data(ser_data),
        .ser_stcp(ser_stcp),
        .ser_n_enable(ser_n_enable)
    );

endmodule