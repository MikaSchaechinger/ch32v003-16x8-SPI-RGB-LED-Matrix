module output_module_tb;
    // Parameters
    localparam CHANNEL_NUMBER = 3;
    localparam SPI_SIZE = 8;
    localparam TEST_SIZE = 4;

    // Signals
    reg clk;
    reg rst;

    typedef logic [SPI_SIZE-1:0] buffer_t [CHANNEL_NUMBER-1:0];
    buffer_t data_in;
    buffer_t data_buffer [0:TEST_SIZE-1];

    reg start_first_column = 0;
    reg start_next_column = 0;
    reg next_data = 0;
    reg extra_bit;

    wire tx_finish;
    
    wire spi_clk;
    wire [CHANNEL_NUMBER-1:0] spi_mosi;
    
    wire ser_clk;
    wire ser_data;
    wire ser_stcp;
    wire ser_n_enable;

    // Instantiate the module
    output_module #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .SPI_SIZE(SPI_SIZE),
        .MSB_FIRST(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .start_first_column(start_first_column),
        .start_next_column(start_next_column),
        .next_data(next_data),
        .extra_bit(extra_bit),
        .tx_finish(tx_finish),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .ser_clk(ser_clk),
        .ser_data(ser_data),
        .ser_stcp(ser_stcp),
        .ser_n_enable(ser_n_enable)
    );

    // Clock generation
    initial begin
        clk = 0;
        for (int i = 0; i < 10000; i++) begin
            #1 clk = ~clk;
        end
    end

    initial begin
        data_buffer[0][0] = 8'h0F;
        data_buffer[1][0] = 8'h0F;
        data_buffer[2][0] = 8'h0F;

        data_buffer[0][1] = 8'hF0;
        data_buffer[1][1] = 8'hF0;
        data_buffer[2][1] = 8'hF0;

        data_buffer[0][2] = 8'hFF;
        data_buffer[1][2] = 8'hFF;
        data_buffer[2][2] = 8'hFF;

        data_buffer[0][3] = 8'h00;
        data_buffer[1][3] = 8'h00;
        data_buffer[2][3] = 8'h00;
    end



    // Test sequence
    initial begin
        rst = 1;
        #5 rst = 0;
        #5;

        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < CHANNEL_NUMBER; j++) begin
                data_in[j] = data_buffer[j][i];  
            end

            for (int k=0; k < TEST_SIZE; ++k) begin
                for (int j=0; j < 1000; ++j) begin
                    #5;
                    if (tx_finish) begin
                        break;
                    end
                end
                if (k == 0) begin
                    if (i == 0) begin
                        start_first_column = 1;
                        #10 start_first_column = 0;
                    end else begin
                        start_next_column = 1;
                        #10 start_next_column = 0;
                    end
                end else begin
                    next_data = 1;
                    #10 next_data = 0;
                end
            end
        end

        $finish;
    end

    initial begin
        $dumpfile("output_module.vcd");
        $dumpvars(0, output_module_tb);
    end
endmodule