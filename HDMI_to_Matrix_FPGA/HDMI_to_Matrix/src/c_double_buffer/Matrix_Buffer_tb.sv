// Puls-gesteuerte Version der Matrix_Buffer_tb

module Matrix_Buffer_tb;

    localparam BYTES_PER_BLOCK = 2250;
    localparam BANK_COUNT = 6;
    localparam BLOCK_COUNT = 2;
    localparam BLOCK_DATA_WIDTH_A = 32;
    localparam BLOCK_DATA_WIDTH_B = 8;
    localparam ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A;
    localparam ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B;
    localparam DATA_COUNT = BANK_COUNT * BLOCK_COUNT;

    logic clk_a = 0;
    logic clk_b = 0;
    logic rst_n;

    logic swap_trigger;
    logic clk_data_in;
    logic clk_data_out;

    logic [$clog2(ADDRESS_NUMBER_A)-1:0] write_address;
    logic [(DATA_COUNT)*BLOCK_DATA_WIDTH_A-1:0] data_in_flat;

    logic [$clog2(ADDRESS_NUMBER_B)-1:0] read_address;
    logic [(DATA_COUNT)*BLOCK_DATA_WIDTH_B-1:0] data_out_flat;

    logic data_valid;


    Matrix_Buffer #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) dut (
        .I_rst_n(rst_n),
        .I_swap_trigger(swap_trigger),

        .I_clka(clk_a),
        .I_clk_data_in(clk_data_in),
        .I_write_address(write_address),
        .I_data_flat(data_in_flat),

        .I_clkb(clk_b),
        .I_clk_data_out(clk_data_out),
        .I_read_address(read_address),
        .O_data_flat(data_out_flat),
        .O_data_valid(data_valid)
    );

    always #5 clk_a = ~clk_a;
    always #7 clk_b = ~clk_b;

    // Reset und Initialisierung
    initial begin
        rst_n = 0;
        clk_data_in = 0;
        clk_data_out = 0;
        swap_trigger = 0;
        write_address = 0;
        read_address = 0;
        #20;
        rst_n = 1;
    end

    int stripe_counter = 0;

    // Schreibe 6 Streifen durch Pulse
    initial begin
        #30;
        repeat (6) begin
            @(posedge clk_a);
            generate_test_pattern(data_in_flat, stripe_counter*2);
            write_address <= stripe_counter;
            #10;
            clk_data_in <= 1;
            #10;
            clk_data_in <= 0;
            stripe_counter+= 1;
            #20;
        end
        @(posedge clk_a);
        swap_trigger <= 1;
        #60;
        swap_trigger <= 0;
        #50000;
        $display("\n Simulation Timeout!");
        $finish;
    end

    // Generiere Testmuster
    task automatic generate_test_pattern(output logic [(DATA_COUNT)*BLOCK_DATA_WIDTH_A-1:0] pattern, input int stripe);
        int number_of_bytes = DATA_COUNT*BLOCK_DATA_WIDTH_A/8;
        int elements_per_color = number_of_bytes / 6; 
        int stripe1 = stripe + 1;
        for (int i = 0; i < elements_per_color; i++) begin
            pattern[i*8 +: 8] =                         {stripe[3:0], 4'b0001};             // Rotbereich, Pannel 0
            pattern[(elements_per_color+i)*8 +: 8] =    {stripe1[3:0], 4'b0001};    // Rotbereich, Pannel 1 
            pattern[(2*elements_per_color+i)*8 +: 8] =  {stripe[3:0], 4'b0011};             // Grünbereich, Pannel 0
            pattern[(3*elements_per_color+i)*8 +: 8] =  {stripe1[3:0], 4'b0011};    // Grünbereich, Pannel 1
            pattern[(4*elements_per_color+i)*8 +: 8] =  {stripe[3:0], 4'b0111};             // Blaubereich, Pannel 0
            pattern[(5*elements_per_color+i)*8 +: 8] =  {stripe1[3:0], 4'b0111};    // Blaubereich, Pannel 1
        end
    endtask

    // Lesen nach Swap
    int read_counter = 0;
    logic starting = 0;
    logic reading = 0;

    logic [8-1:0] stream_bytes [DATA_COUNT-1:0];

    always @(posedge clk_b) begin
        if (rst_n) begin
            if (swap_trigger && data_valid && !reading) begin
                reading <= 1;
                read_counter <= 0;
                clk_data_out <= 0;
                starting <= 1;
            end

            if (reading) begin
                if (starting) begin
                    starting <= 0;
                    clk_data_out <= 1;
                    read_counter <= 0;
                    read_address <= 0;
                end else begin
                    for (int i = 0; i < DATA_COUNT; i++) begin
                        stream_bytes[i] = data_out_flat[i*8 +: 8];
                    end
                    #1;
                    read_counter += 1;
                    read_address += 1;
                end
            end


            if (read_counter == 24) begin
                reading <= 0;
                #100;
                $display("\n✅ Alle 24 Daten ausgelesen. Test abgeschlossen.");
                $finish;
            end
        end
    end

    initial begin
        $dumpfile("Matrix_Buffer_tb.vcd");
        $dumpvars(0, Matrix_Buffer_tb);
    end

    // Streams as single vectors for WaveTrace analysis

    initial begin
        for (int i = 0; i < 12; i++) begin
            $dumpvars(0, stream_bytes[i]);
        end
    end


endmodule
