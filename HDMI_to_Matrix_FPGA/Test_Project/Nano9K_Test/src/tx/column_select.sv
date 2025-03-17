module column_select #(
    parameter COLUMN_NUMBER = 3
) (
    input wire clk,
    input wire rst,
    
    input wire select_next, // Selects the next column
    input wire extra_bit,

    output reg ready,      // High when the next column can be selected

    output wire ser_clk,
    output wire ser,
    output reg stcp,
    output reg enable
);

    //============== Type Definitions ===============

    typedef enum logic [1:0] { 
        STARTUP,    // After reset.
        IDLE,       // Ready to select the next column.
        SENDING_FIRST,    // Sending the column data. Select Bit is active
        SENDING_OTHER     // Sending the column data. Select bit is inactive
    } state_t;


    //============== Internal Signals ===============
    reg select_next_internal = 0;
    state_t state = STARTUP;
    state_t next_state = STARTUP;
    reg [7:0] column_data;          // Data to be sent to the column.

    localparam int COLUMN_COUNTER_WIDTH = $clog2(COLUMN_NUMBER+1);
    reg [COLUMN_COUNTER_WIDTH-1:0] column_counter = 0;

    reg [3:0] stcp_delay = 0;

    reg [7:0] send_data = 8'hFF;

    reg start_tx = 0;
    wire tx_finish;

    reg select_lock = 0;    // Reset: stcp was written.  Set: When data was send
    //=============== Code Logic ===============

    always @(posedge select_next or negedge select_lock) begin
        if (select_lock == 0) begin
            select_next_internal <= 0;
        end else if (select_next) begin
            if (state == IDLE) begin
                select_next_internal <= 1;
            end
        end
    end


    always @(posedge rst or posedge select_next_internal or posedge clk) begin
        if (rst) begin
            stcp_delay <= 0;
        end else if (select_next_internal) begin
            stcp_delay[0] <= 1;
        end else if (clk) begin
            if (stcp_delay) begin
                stcp_delay[0] <= 0;
                stcp_delay[1] <= stcp_delay[0];
                stcp_delay[2] <= stcp_delay[1];
                stcp <= 1;
            end else  begin
                stcp <= 0;
            end

            if (stcp_delay[2]) begin
                select_lock <= 0;   // stcp was written, release the lock
            end
        end
    end



    // send_datta control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_data <= 8'hFF;
        end else if (clk) begin
            send_data[1] <= extra_bit;

            // select panel bit control
            if (state == SENDING_FIRST) begin
                send_data[0] <= 0;
            end else if (state == SENDING_OTHER) begin
                send_data[0] <= 1;
            end
        end
    end



    // State Machine Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STARTUP;
        end else begin
            state <= next_state;
        end
    end

    // State Machine Logic
    always_comb begin
        case (state)
            STARTUP: begin
                ready = 0;
                // Initialize the column data
                if (column_counter == COLUMN_NUMBER - 1) begin
                    next_state = SENDING_FIRST;
                end else begin
                    next_state = STARTUP;
                end
            end
            IDLE: begin
                // Shift-Register Data is ready and waiting for the next column to be selected (STCP)
                ready = 1;
            end
            SENDING_FIRST: begin
                // Shift-Register Data is being sent to the column
                ready = 0;  
                if (start_tx) begin
                    next_state = IDLE;
                end else begin
                    next_state = SENDING_FIRST;
                end
            end
            SENDING_OTHER: begin
                // Shift-Register Data is being sent to the column
                ready = 0;
                if (start_tx) begin
                    next_state = IDLE;
                end else begin
                    next_state = SENDING_OTHER;
                end
            end
        endcase
    end



    // 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            column_counter <= 0;
        end else if (state == STARTUP) begin
            if (tx_finish) begin
                start_tx <= 1;
                column_counter <= column_counter + 1;
            end else begin
                start_tx <= 0;
            end
        end else if (state == SENDING_FIRST) begin
            if (select_lock == 0) begin
                if (tx_finish) begin
                    start_tx <= 1;
                    column_counter <= 0;
                    select_lock <= 1;
                end 
            end
        end else if (state == SENDING_OTHER) begin
            if (select_lock == 0) begin
                if (tx_finish) begin
                    start_tx <= 1;
                    column_counter <= column_counter + 1;
                    select_lock <= 1;
                end 
            end
        end else if (state == IDLE) begin
            start_tx <= 0;
        end
    end





    nspi_tx #(
        .CHANNEL_NUMBER(1),
        .SPI_SIZE(8),
        .MSB_FIRST(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start_tx(start_tx),
        .tx_finish(tx_finish),
        .data_in(send_data),
        .spi_clk(ser_clk),
        .spi_mosi(ser)
    );


    always @(posedge clk) begin
        if (rst) begin
            enable <= 1;
        end else if (clk) begin
            if (state == IDLE) begin
                enable <= 0;
            end
        end
    end
            


endmodule