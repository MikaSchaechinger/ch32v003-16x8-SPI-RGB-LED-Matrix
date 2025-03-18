module column_select_tb;
    // Parameters
    localparam COLUMN_NUMBER = 3;

    // Signals
    reg clk;
    reg rst;
    reg select_first=0;
    reg select_next=0;
    reg extra_bit = 0;

    wire ready;
    wire stcp;
    wire ser;
    wire ser_clk;
    wire enable;

    // Instantiate the module
    column_select cs (
        .clk(clk),
        .rst(rst),
        .select_first(select_first),
        .select_next(select_next),
        .extra_bit(extra_bit),
        .ready(ready),
        .ser_stcp(stcp),
        .ser_data(ser),
        .ser_clk(ser_clk),
        .ser_n_enable(enable)
    );

    // Clock generation
    initial begin
        clk = 0;
        for (int i = 0; i < 1000; i++) begin
            #5 clk = ~clk;
        end
    end


   // Reset generation
    initial begin
        rst = 1;
        #20 rst = 0;

        #10;

        for (int i = 0; i < 3; i++) begin

            for (int j=0; j < 1000; ++j) begin
                #10;
                if (ready) begin
                    break;
                end
            end

            select_first = 1;
            #10 select_first = 0;
            


            for (int j=0; j < 1000; ++j) begin
                #10;
                if (ready) begin
                    break;
                end
            end
            
            select_next = 1;
            #10 select_next = 0;
        end



    end

    initial begin
        $dumpfile("column_select_tb.vcd");
        $dumpvars(0, column_select_tb);
    end

endmodule