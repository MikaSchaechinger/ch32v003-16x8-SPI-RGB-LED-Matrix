
module HDMI_to_Matrix_top_tb;

    // Parameter
    localparam real CLK_PERIOD_SYSCLK = 37.037; // ~27 MHz
    localparam real CLK_PERIOD_RGBCLK = 10.0;   // 100 MHz, angenommen für Simulation

    // Inputs
    logic sys_clk_27MHz;
    logic [1:0] btn;
    logic I_tmds_clk_p;
    logic I_tmds_clk_n;
    logic [2:0] I_tmds_data_p;
    logic [2:0] I_tmds_data_n;

    // Outputs
    wire spi_clk;
    wire [7:0] spi_mosi;
    wire shift_clk;
    wire shift_ser;
    wire shift_stcp;
    wire shift_en;
    wire [5:0] led;

    // DUT
    HDMI_to_Matrix_top dut (
        .sys_clk_27MHz(sys_clk_27MHz),
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

    // Clock generation
    initial sys_clk_27MHz = 0;
    always #(CLK_PERIOD_SYSCLK/2.0) sys_clk_27MHz = ~sys_clk_27MHz;

    // Reset logic
    initial begin
        btn[0] = 0;  // Active low reset
        btn[1] = 0;  // Unused
        I_tmds_clk_p = 0;
        I_tmds_clk_n = 1;
        I_tmds_data_p = 3'b000;
        I_tmds_data_n = 3'b111;

        // Initial delay
        #100;
        btn[0] = 1;  // Deassert reset

        // Run simulation
        #100000;

        $display("Simulation finished.");
        $finish;
    end


    initial begin
        $dumpfile("HDMI_to_Matrix_top_tb.vcd");
        $dumpvars(0, HDMI_to_Matrix_top_tb);
    end

endmodule
