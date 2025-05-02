module Output_Module #(
    parameter CHANNEL_NUMBER = 3,
    parameter SPI_SIZE = 8,
    parameter MSB_FIRST = 1
)(
    input wire I_clk,
    input wire I_rst_n,

    input wire [SPI_SIZE-1:0] I_data_in [CHANNEL_NUMBER-1:0],
    input wire I_next_image,
    input wire I_next_column,
    input wire I_next_data,
    input wire I_extra_bit,

    output reg O_tx_finish,

    output wire O_spi_clk,
    output wire [CHANNEL_NUMBER-1:0] O_spi_mosi,

    output wire O_ser_clk,
    output wire O_ser_data,
    output wire O_ser_stcp,
    output wire O_ser_n_enable
);


    //============== Type Definitions ===============
    typedef enum logic [2:0] { 
        S0_RST,
        S1_IDLE, 
        S20_SEL_FIRST, 
        S21_SEL_NEXT, 
        S3_WAIT_FOR_READY,
        S4_START_SPI_TX,
        S5_WAIT_FOR_SPI_TX_FINISH
    } state_t;

    //============== Internal Signals =================
    // Connection to Moduls

    state_t state = S0_RST;
    state_t next_state = S0_RST;
    wire column_select_ready;
    wire spi_tx_finish;
    reg spi_start_tx = 0;
    reg select_first = 0;
    reg select_next = 0;

    //=============== Code Logic ===============

    always_ff @(posedge I_clk or posedge I_rst_n) begin
        if (I_rst_n) begin
            state <= S0_RST;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            S0_RST: begin   // 0
                if (column_select_ready) begin
                    next_state = S1_IDLE;
                end else begin
                    next_state = S0_RST;
                end
                O_tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
            S1_IDLE: begin  // 0
                if (I_next_image) begin
                    next_state = S20_SEL_FIRST;
                end else if (I_next_column) begin
                    next_state = S21_SEL_NEXT;
                end else if (I_next_data) begin
                    next_state = S4_START_SPI_TX;
                end else begin
                    next_state = S1_IDLE;
                end
                O_tx_finish = 1;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
            S20_SEL_FIRST: begin    // 1
                if (column_select_ready == 0) begin
                    next_state = S3_WAIT_FOR_READY;
                end else begin
                    next_state = S20_SEL_FIRST;
                end
                O_tx_finish = 0;
                select_first = 1;
                select_next = 0;
                spi_start_tx = 0;
            end
            S21_SEL_NEXT: begin     // 2
                if (column_select_ready == 0) begin
                    next_state = S3_WAIT_FOR_READY;
                end else begin
                    next_state = S21_SEL_NEXT;
                end
                O_tx_finish = 0;
                select_first = 0;
                select_next = 1;
                spi_start_tx = 0;
            end
            S3_WAIT_FOR_READY: begin    // 3
                if (column_select_ready==1) begin
                    next_state = S4_START_SPI_TX;
                end else begin
                    next_state = S3_WAIT_FOR_READY;
                end
                O_tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
            S4_START_SPI_TX: begin  // 4
                if (spi_tx_finish == 0) begin
                    next_state = S5_WAIT_FOR_SPI_TX_FINISH;
                end else begin
                    next_state = S4_START_SPI_TX;
                end
                O_tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 1;
            end
            S5_WAIT_FOR_SPI_TX_FINISH: begin    // 5
                if (spi_tx_finish) begin
                    next_state = S1_IDLE;
                end else begin
                    next_state = S5_WAIT_FOR_SPI_TX_FINISH;
                end
                O_tx_finish = 0;
                select_first = 0;
                select_next = 0;
                spi_start_tx = 0;
            end
            default: begin
                next_state = S1_IDLE;
                O_tx_finish = 0;
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
        .clk(I_clk),
        .rst(I_rst_n),
        .start_tx(spi_start_tx),
        .tx_finish(spi_tx_finish),
        .data_in(I_data_in),
        .spi_clk(O_spi_clk),
        .spi_mosi(O_spi_mosi)
    );


    column_select cs (
        .clk(I_clk),
        .rst(I_rst_n),
        .select_first(select_first),
        .select_next(select_next),
        .extra_bit(I_extra_bit),
        .ready(column_select_ready),
        .ser_clk(O_ser_clk),
        .ser_data(O_ser_data),
        .ser_stcp(O_ser_stcp),
        .ser_n_enable(O_ser_n_enable)
    );

endmodule