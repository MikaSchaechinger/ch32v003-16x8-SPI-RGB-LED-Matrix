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
        start_tx = 0;
        data_in[0] = 8'h0F;
        data_in[1] = 8'hF0;

        // Test case 1: Start transmission
        #100 start_tx = 1;
        #10 start_tx = 0;
        #100;

        // Test case 2: Check transmission
        #100;
        //assert(spi_clk == 1);
        //(spi_mosi[0] == 1);

        // Test case 3: Check transmission finish
        #100;
        //assert(tx_finish == 1);

        // Test case 4: Multiple transmissions
        #100 start_tx = 1;
        #10 start_tx = 0;
        #100;
        data_in[0] = 8'hBB;
        #100 start_tx = 1;
        #10 start_tx = 0;
        #100;

        $finish;
    end

    initial begin
        $dumpfile("nspi_tx_tb.vcd");
        $dumpvars(0, nspi_tx_tb);
    end
endmodule