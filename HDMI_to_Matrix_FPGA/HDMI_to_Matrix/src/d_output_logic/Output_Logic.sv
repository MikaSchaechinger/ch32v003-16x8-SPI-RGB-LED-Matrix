module Output_Logic #(
    parameter int SPI_CHANNEL_NUMBER = 4,
    parameter int MAX_WIDTH = 1920,
    parameter int MAX_HEIGHT = 1080,
    parameter int PANEL_WIDTH = 8,
    parameter int PANEL_HEIGHT = 4,
    parameter int COLOR_COUNT = 3,

    parameter int BYTES_PER_BLOCK = 2250,
    parameter int BLOCK_DATA_WIDTH_B = 8,  // Read Port
    parameter int BANK_COUNT = 6,
    parameter int BLOCK_COUNT = 2,
    parameter int ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B, // Read Port
    parameter int BYTES_PER_READ = BANK_COUNT * BLOCK_COUNT
) (
    input  logic                         I_clk,
    input  logic                         I_rst_n,  
    // Communication with Matrix_Buffer
    input  logic                         I_start_line_out,   
    input  logic                         I_hs_detected, // This is the signal for the start of a new line after this line. Currently, should be always high, because data is one complete line.
    input  logic                         I_vs_detected, // This is the signal for the start of a new image after this line
    input  logic [$clog2(MAX_WIDTH)-1:0]    I_image_width,
    input  logic [$clog2(MAX_HEIGHT)-1:0]   I_image_height,
    input  logic                         I_image_valid,
    
    input  logic                         I_data_valid,
    output logic                         O_read_enable,
    output logic [$clog2(ADDRESS_NUMBER_B)-1:0] O_read_address,
    input logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0] I_data_flat,
    // Communication with Output_Module
    input  logic                         I_tx_finish,
    output logic                         O_next_data,
    output logic                         O_next_column,
    output logic                         O_next_image,
    output logic [SPI_CHANNEL_NUMBER*BLOCK_DATA_WIDTH_B-1:0] O_data_flat
);
    // TODO: (Optional): Fill Panels with zeros, if they are partially outside of the image width and height. (Irrelevant, if only a subset of the image is used.)
    // ========== Address Calculation ==========
    //
    // The Address to read the data is now complicated too. 
    // In One Read (One Address) 6*2=12 SPI Channels are read out. With Addres 0-23 all Data for the first 12 SPI Channels are read out.
    // But if more channels exist, The Other Channels must be read simultaneously, too. 
    // For 48 Channels (384 Pixel width), for one Data transmission, 4 readouts are needed. The Address sequence would be:
    // 0, 24, 48, 72, 96  (send Data)
    // 1, 25, 49, 73, 97  (send Data)
    // 2, 26, 50, 74, 98  (send Data)
    // ...
    // 23, 47, 71, 95, 119 (send Data)
    // One HDMI Line is finished

    // Next we must calculate, which image width is covered by the SPI channels and how many read cycles are needed to cover the whole image width (I_image_width)
    // When ONE_READ_COVERED_WIDTH - 1 ist added: This prevents the division from rounding down to 0, when the image width is smaller than ONE_READ_COVERED_WIDTH.
    localparam MAX_POSSIBLE_SPI_CHANNELS = MAX_WIDTH / PANEL_WIDTH;                 // 240 Thats the maximum number needed for the max possible HDMI Width
    localparam ONE_READ_COVERED_WIDTH = BANK_COUNT * BLOCK_COUNT * PANEL_WIDTH;     //  96 The image width which is covered by one readout (one address)
    localparam SPI_COVERED_WIDTH = SPI_CHANNEL_NUMBER * PANEL_WIDTH;                //  64 The image width which is covered by the SPI channels
    localparam MAX_READ_CYCLES_NEEDED = (MAX_WIDTH + ONE_READ_COVERED_WIDTH - 1) / ONE_READ_COVERED_WIDTH; // 3  The maximum number of read cycles needed to cover the whole image width (I_image_width)
    
    logic [$clog2(MAX_READ_CYCLES_NEEDED)-1:0] cycles_needed; // The number of read cycles needed to cover the whole image width (I_image_width)

    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            cycles_needed <= 0;
        end else begin
            cycles_needed <= (I_image_width + ONE_READ_COVERED_WIDTH - 1) / ONE_READ_COVERED_WIDTH;
        end
    end

    initial begin
        if (SPI_CHANNEL_NUMBER > MAX_POSSIBLE_SPI_CHANNELS) begin
            $error("SPI_CHANNEL_NUMBER is greater than MAX_POSSIBLE_SPI_CHANNELS. Please check the parameters.");
        end
    end

    // Next we need tree addresses:
    // 1. base_address: Counts from 0 to 23 for all reads for the channels 0-11
    // 2. read_address: This ist the base_address with a offset for the other channels

    localparam MAX_BASE_ADDRESS = PANEL_WIDTH * COLOR_COUNT;   // 24
    localparam MAX_READ_ADDRESS = MAX_BASE_ADDRESS * MAX_READ_CYCLES_NEEDED; // 24 * 4 = 96

    logic [$clog2(MAX_BASE_ADDRESS)-1:0] base_address;         // The base address for the readout (0-23)
    logic [$clog2(MAX_READ_ADDRESS)-1:0] read_address;         // The read address for the readout (0-96)
    logic [$clog2(MAX_READ_CYCLES_NEEDED)-1:0] cycles_done;   // The number of read cycles done so far
    // Now comes the calculation of the read address:
    always_comb begin
        read_address = base_address + (cycles_done * MAX_BASE_ADDRESS);
    end

    // read_address must be assigned to O_read_address. O_read_address should be wider than read_address. This sould be checked too.
    initial begin
        if ($bits(O_read_address) < $bits(read_address)) begin
            $error("O_read_address is not wide enough for read_address. Please check the parameters.");
        end
    end

    assign O_read_address = {{($bits(O_read_address) - $bits(read_address)){1'b0}}, read_address};


    
    // Now the Address can be controlled with base_address and cycles_done.

    // Next we need to track the current line we are in. The total number of lines is passed by I_image_height. 
    // The line changes when I_start_line_out is set and I_hs_detected
    // A reset of the counter happens by I_vs_detected. This is the start of a new image.
    typedef enum logic [1:0] {
        SEND_BUFFER_DATA = 2'b00,
        SEND_BLANK_DATA = 2'b01,
        SEND_FINISH = 2'b10
    } send_t;
    send_t send_data; // The type of data to be sent (buffer data or blank data)

    logic [$clog2(MAX_HEIGHT+PANEL_HEIGHT)-1:0] current_line; // The current line we are in (0-1080)
    logic increase_current_line; // A signal to increase the current line


    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            current_line <= 0;
        end else begin
             if (I_vs_detected) begin
                current_line <= 0;
            end else if (I_hs_detected && I_start_line_out) begin
                current_line <= current_line + 1;
            end else if (increase_current_line) begin
                current_line <= current_line + 1;
            end
        end
    end

    logic [$clog2(MAX_HEIGHT+PANEL_HEIGHT)-1:0] total_lines; // The total number of lines including the blank lines 

    always_comb begin
        total_lines = ((I_image_height + PANEL_HEIGHT - 1) / PANEL_HEIGHT) * PANEL_HEIGHT;

        if (current_line < { {( $bits(current_line) - $bits(I_image_height) ){1'b0} }, I_image_height }) begin
            send_data = SEND_BUFFER_DATA;
        end else begin
            if (current_line < total_lines) begin
                send_data = SEND_BLANK_DATA;
            end else begin
                send_data = SEND_FINISH;
            end
        end
    end 

    // Indicator Flag when a new panel row is starting
    logic new_panel_row; // A signal to indicate when a new panel row is starting
    assign new_panel_row = (current_line % PANEL_HEIGHT == 0); // A new panel row is starting when the current line is a multiple of PANEL_HEIGHT


    //=========== State Machine ===========
    //
    // Next is a state machine, which controls the readout of the data. 
    logic [$clog2(MAX_READ_CYCLES_NEEDED)-1:0] cycles_done_next; // The number of read cycles done so far in the next cycle
    logic [$clog2(MAX_BASE_ADDRESS)-1:0] base_address_next;         // The base address for the readout (0-23)




    typedef enum logic [2:0] { 
        S0_IDLE, 
        S1_PREPARE_READ,
        S2_READ,
        S3_WAIT_FOR_TX_FINISH,
        S4_SEND_DATA
    } state_t;
    state_t state, next_state;


    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            state <= S0_IDLE;
        end else begin
            state <= next_state;
            cycles_done <= cycles_done_next;
            base_address <= base_address_next;
        end
    end



    logic address_reset;

    int outputted_pixel_number = 0;
    always_comb begin
        case (state)
            S0_IDLE: begin
                O_read_enable = 0;
                if (I_start_line_out && I_image_valid) begin
                    next_state = S1_PREPARE_READ;
                end else begin
                    next_state = S0_IDLE;
                end
                cycles_done_next = 0;
                base_address_next = 0;
                O_next_data = 0;
                O_next_column = 0;
                O_next_image = 0;
            end
            S1_PREPARE_READ: begin      // Read is prepared and Data is available in the next cycle
                O_read_enable = 1;
                next_state = S2_READ;
                cycles_done_next = 1;
                base_address_next = base_address;
                O_next_data = 0;
                O_next_column = 0;
                O_next_image = 0;
            end
            S2_READ: begin
                if (cycles_done < cycles_needed) begin  // get Data and ask for the next readout
                    O_read_enable = 1;
                    next_state = S2_READ;
                    cycles_done_next = cycles_done + 1;
                end else begin                          // get last Data
                    O_read_enable = 0;
                    next_state = S3_WAIT_FOR_TX_FINISH;
                    cycles_done_next = 0;
                end
                base_address_next = base_address;
                O_next_data = 0;
                O_next_column = 0;
                O_next_image = 0;
            end
            S3_WAIT_FOR_TX_FINISH: begin
                O_read_enable = 0;
                if (I_tx_finish) begin
                    next_state = S4_SEND_DATA;
                end else begin
                    next_state = S3_WAIT_FOR_TX_FINISH;
                end
                cycles_done_next = cycles_done;
                base_address_next = base_address;
                O_next_data = 0;
                O_next_column = 0;
                O_next_image = 0;
            end
            S4_SEND_DATA: begin
                O_read_enable = 0;
                if (base_address == 0 && I_vs_detected) begin
                    O_next_image = 1;
                    O_next_column = 0;
                    O_next_data = 0;
                end else if (base_address == 0 && new_panel_row) begin
                    O_next_image = 0;
                    O_next_column = 1;
                    O_next_data = 0;
                end else begin
                    O_next_image = 0;
                    O_next_column = 0;
                    O_next_data = 1;
                end

                cycles_done_next = cycles_done;
                base_address_next = base_address + 1;

                if (base_address == MAX_BASE_ADDRESS - 1) begin
                    next_state = S0_IDLE;
                end else begin
                    next_state = S1_PREPARE_READ;
                end
            end
            default: begin
                next_state = S0_IDLE;
                O_read_enable = 0;
                cycles_done_next = 0;
                base_address_next = 0;
                O_next_data = 0;
                O_next_column = 0;
                O_next_image = 0;
            end
        endcase
    end


    







    // Divide I_data_flat into multiple channles
    logic [BLOCK_DATA_WIDTH_B-1:0] data_in [BANK_COUNT*BLOCK_COUNT-1:0];

    always_comb begin
        for (int i = 0; i < BANK_COUNT*BLOCK_COUNT; i++) begin
            data_in[i] = I_data_flat[(i+1)*BLOCK_DATA_WIDTH_B-1 -: BLOCK_DATA_WIDTH_B];
        end
    end

    // The Data is available, in S2_READ. The Data is one clock cycle delayed, but for this the extra state S1_PREPARE_READ is used.
    // We use SPI_CHANNEL_NUMBER channels. But 12 (BANK_COUNT*BLOCK_COUNT) channels are read out in one readout. There are "cycles_needed" readouts for one line. The current readout is "cycles_done", but because of the delay, it has to be "cycles_done - 1".

    int base_channel;
    logic [BLOCK_DATA_WIDTH_B-1:0] data_out_arr [SPI_CHANNEL_NUMBER-1:0]; // The data for the SPI channels

    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            // Set complete output to 0
            for (int i = 0; i < SPI_CHANNEL_NUMBER; i++) begin
                data_out_arr[i] <= '0;
            end
        end else begin
            // Data is only valid when we are in the S2_READ state.
            if (state == S2_READ) begin
                // cycles done starts here with 1, so we have to subtract 1 to get the current readout
                // The read data is for 12 successive channels. If there are not enough SPI channels, the data is ignored.
                base_channel = (cycles_done - 1) * BANK_COUNT * BLOCK_COUNT;
                for (int i = 0; i < BANK_COUNT*BLOCK_COUNT; i++) begin
                    if (base_channel + i < SPI_CHANNEL_NUMBER) begin
                        data_out_arr[base_channel + i] <= data_in[i];
                    end
                end
            end
        end
    end


    // Pass data_out_arr to O_data_flat
    always_comb begin
        for (int i = 0; i < SPI_CHANNEL_NUMBER; i++) begin
            O_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B] = data_out_arr[i];
        end
    end


endmodule