module nspi_tx_tb;
    // Parameters
    localparam CHANNEL_NUMBER = 2;
    localparam SPI_SIZE = 8;

    // Signals
    reg clk;
    reg rst;
    reg start_tx;
    wire tx_finish;
    reg [SPI_SIZE-1:0] data_in [CHANNEL_NUMBER-1:0];
    wire spi_clk;
    wire [CHANNEL_NUMBER-1:0] spi_mosi;

    // Instantiate the module
    nspi_tx #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .SPI_SIZE(SPI_SIZE),
        .MSB_FIRST(1)
    ) spi_tx (
        .clk(clk),
        .rst(rst),
        .start_tx(start_tx),
        .tx_finish(tx_finish),
        .data_in(data_in),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi)
    );

    // Clock generation
    initial begin
        clk = 0;
        for (int i = 0; i < 10000; i++) begin
            #1 clk = ~clk;
        end
    end

    // Reset generation
    initial begin
        rst = 1;
        #20 rst = 0;
    end

    // Test sequence
    initial begin
        rst = 1;
        #20 rst = 0;

        data_in[0] = 8'h0F;
        data_in[1] = 8'hF0;

        #10;

        for (int i = 0; i < 4; i++) begin
            // Warten, bis tx_finish == 1
            for (int j = 0; j < 1000; j++) begin
                #10;
                if (tx_finish) begin
                    break;
                end
            end

            // start_tx setzen
            start_tx = 1;
            #10 start_tx = 0;

            // Warten, bis tx_finish == 0
            for (int j = 0; j < 1000; j++) begin
                #10;
                if (!tx_finish) begin
                    break;
                end
            end
        end

        $finish;
    end


    initial begin
        $dumpfile("nspi_tx_tb.vcd");
        $dumpvars(0, nspi_tx_tb);
    end
endmodule