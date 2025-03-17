module column_select_tb;
    // Parameters
    localparam COLUMN_NUMBER = 3;

    // Signals
    reg clk;
    reg rst;
    reg select_next;
    reg extra_bit;

    wire ready;
    wire stcp;
    wire ser;
    wire ser_clk;
    wire enable;

    // Instantiate the module
    column_select #(
        .COLUMN_NUMBER(3)
    ) dut (
        .clk(clk),
        .rst(rst),
        .select_next(select_next),
        .extra_bit(extra_bit),
        .ready(ready),
        .stcp(stcp),
        .ser(ser),
        .ser_clk(ser_clk),
        .enable(enable)
    );

    // Clock generation
    initial begin
        clk = 0;
        for (int i = 0; i < 1000; i++) begin
            #10 clk = ~clk;
        end
    end


   // Reset generation
    initial begin
        rst = 1;
        #20 rst = 0;

        // After Reser, the startup sequence is running


    end

    initial begin
        $dumpfile("column_select_tb.vcd");
        $dumpvars(0, column_select_tb);
    end

endmodule