
module LED_Matrix_top_tb;

    // Testbench Signale
    reg clk;
    reg [1:0] btn;
    reg I_tmds_clk_p;
    reg I_tmds_clk_n;
    reg [2:0] I_tmds_data_p;
    reg [2:0] I_tmds_data_n;
    
    wire spi_clk;
    wire [2:0] spi_mosi;
    wire shift_clk;
    wire shift_ser;
    wire shift_stcp;
    wire shift_en;
    wire [5:0] led;

    // Taktgenerierung
    always #1 clk = ~clk;  // 100 MHz Takt (10 ns Periode)
    
    // Instanz des DUT (Device Under Test)
    LED_Matrix_top #(
        .CHANNEL_NUMBER(3),
        .BYTES_PER_MATRIX(8*16*3),
        .DIV_FACTOR(2)
    )
    uut (
        .clk(clk),
        .btn(btn),
        .I_tmds_clk_p(I_tmds_clk_p),
        .I_tmds_clk_n(I_tmds_clk_n),
        .I_tmds_data_p(I_tmds_data_p),
        .I_tmds_data_n(I_tmds_data_n),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .shift_clk(shift_clk),
        .shift_ser(shift_ser),
        .shift_stcp(shift_stcp),
        .shift_en(shift_en),
        .led(led)
    );
    
    initial begin
        // Initialisierung
        clk = 0;
        btn = 2'b11;
        I_tmds_clk_p = 0;
        I_tmds_clk_n = 1;
        I_tmds_data_p = 3'b000;
        I_tmds_data_n = 3'b111;

        // Reset setzen
        #5;
        btn[0] = 0;    // Reset aktivieren
        #20;
        btn[0] = 1;     // Reset deaktivieren

        #500 btn[1] = 1; // Bildwechsel aktivieren
        #500 btn[1] = 0; // Bildwechsel deaktivieren    
        // Simulation beenden
        #100000
        $finish;
    end


    initial begin
        $dumpfile("LED_Matrix_top.vcd");
        $dumpvars(0, LED_Matrix_top_tb);
    end
endmodule