module column_select (
    input wire clk,
    input wire rst,
    
    input wire select_first,    // Selects the first column, must be high until ready is low
    input wire select_next,     // Selects the next column,  must be high until ready is low
    input wire extra_bit,

    output reg ready,      // High when the next column can be selected

    output wire ser_clk,
    output wire ser_data,
    output reg ser_stcp = 0,
    output reg ser_n_enable = 0
);

    //============== Type Definitions ===============

    typedef enum logic [2:0] { 
        S0_STARTUP,             // After reset, initialize ser_n_enable and counter
        S1_WAIT_FOR_TX_FINISH,  // Wait for the Column Data to be sent
        S2_STCP,                // Send the STCP signal
        S3_WAIT_FOR_SELECT,     // Wait for select_first or select_next
        S40_SELECT_FIRST,       // Select the first column
        S41_SELECT_NEXT,        // Select the next column
        S5_SEND_DATA            // Send the data to the column
    } state_t;


    //============== Internal Signals =================
    state_t state = S0_STARTUP;
    state_t next_state = S0_STARTUP;
    reg [7:0] column_data = 8'h00;          // Data to be sent to the column.
    reg [1:0] counter = 0;          // Counts the number of select_first, to enable the matrix after 2 iterations

    reg start_tx = 0;
    wire tx_finish;

    //=============== Code Logic ===============






    // State Machine Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0_STARTUP;
            ser_n_enable = 1;
        end else if (clk) begin
            state <= next_state;
            column_data[1] = extra_bit;     // Extra bit to be sent to the column

            // spcial logic for S40 and S41
            if (next_state == S40_SELECT_FIRST) begin
                if (counter == 2) begin
                    ser_n_enable = 0;
                end else begin
                    counter = counter + 1;
                end
                column_data[0] = 0;     // Active Low. Select the first column
            end else if (next_state == S41_SELECT_NEXT) begin
                column_data[0] = 1;     // Active Low. Select the next column
            end
        end
    end



    // State Machine Logic
    always_comb begin
        case (state)
            S0_STARTUP: begin
                next_state = S1_WAIT_FOR_TX_FINISH;
                counter = 0;
                ser_stcp = 0;
                ready = 0;
                start_tx = 0;
            end
            S1_WAIT_FOR_TX_FINISH: begin
                start_tx = 0;
                if (tx_finish) begin
                    next_state = S2_STCP;
                end else begin
                    next_state = S1_WAIT_FOR_TX_FINISH;
                end
                // Should not change
                ser_stcp = 0;
                ready = 0;
            end
            S2_STCP: begin
                ser_stcp = 1;
                next_state = S3_WAIT_FOR_SELECT;
                // Should not change
                ready = 0;
                start_tx = 0;
            end
            S3_WAIT_FOR_SELECT: begin
                ser_stcp = 0;
                ready = 1;
                if (select_first) begin
                    next_state = S40_SELECT_FIRST;
                end else if (select_next) begin
                    next_state = S41_SELECT_NEXT;
                end else begin
                    next_state = S3_WAIT_FOR_SELECT;
                end
                // Should not change
                start_tx = 0;
            end
            S40_SELECT_FIRST: begin
                ready = 0;
                next_state = S5_SEND_DATA;

                // Should not change
                ser_stcp = 0;
                start_tx = 0;
            end
            S41_SELECT_NEXT: begin
                ready = 0;
                next_state = S5_SEND_DATA;

                // Should not change
                ser_stcp = 0;
                start_tx = 0;
            end
            S5_SEND_DATA: begin
                start_tx = 1;
                next_state = S1_WAIT_FOR_TX_FINISH;
                // Shoud not change
                ready = 0;
                ser_stcp = 0;
            end
            default: begin
                next_state = S0_STARTUP;
                ser_stcp = 0;
                ready = 0;
                start_tx = 0;
            end
        endcase
    end







    nspi_tx #(
        .CHANNEL_NUMBER(1),
        .SPI_SIZE(8),
        .MSB_FIRST(1)
    ) shift_reg (
        .clk(clk),
        .rst(rst),
        .start_tx(start_tx),
        .tx_finish(tx_finish),
        .data_in(column_data),
        .spi_clk(ser_clk),
        .spi_mosi(ser_data)
    );



endmodule