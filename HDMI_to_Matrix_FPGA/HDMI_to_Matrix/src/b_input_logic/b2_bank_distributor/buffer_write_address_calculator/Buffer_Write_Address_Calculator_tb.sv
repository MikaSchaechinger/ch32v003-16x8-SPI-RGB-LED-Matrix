module Buffer_Write_Address_Calculator_tb;

    parameter BANK_COUNT = 3;
    parameter BLOCK_DEPTH = 480;
    
    logic [$clog2(BLOCK_DEPTH)-1:0] I_global_address;
    logic [$clog2(BLOCK_DEPTH)-1:0] O_bank_address [0:BANK_COUNT-1];


    Buffer_Write_Address_Calculator #(
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_DEPTH(BLOCK_DEPTH)
    ) dut (
        .I_global_address(I_global_address),
        .O_bank_address(O_bank_address)
    );

    initial begin

        for (int i = 0; i < 10; i++) begin
            I_global_address = i;
            #1;
        end
        $finish;
    end


    initial begin
        $dumpfile("Buffer_Write_Address_Calculator_tb.vcd");
        $dumpvars(0, Buffer_Write_Address_Calculator_tb);
    end


endmodule
