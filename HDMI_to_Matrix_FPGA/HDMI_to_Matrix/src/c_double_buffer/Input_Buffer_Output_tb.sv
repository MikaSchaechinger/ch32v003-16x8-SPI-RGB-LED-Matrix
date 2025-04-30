module Input_Buffer_Output_tb();

    `define SIMULATION 1
    // Parameter
    localparam BYTES_PER_BLOCK = 2250;
    localparam BANK_COUNT = 6;
    localparam BLOCK_COUNT = 2;
    localparam BLOCK_DATA_WIDTH_A = 32;
    localparam BLOCK_DATA_WIDTH_B = 8;
    localparam ADDRESS_NUMBER_A = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_A;
    localparam ADDRESS_NUMBER_B = (BYTES_PER_BLOCK * 8) / BLOCK_DATA_WIDTH_B;
    localparam int DATA_COUNT = BANK_COUNT * BLOCK_COUNT;

    // Clocks
    logic clk_a;
    logic clk_b;
    always #5 clk_a = ~clk_a; // 100 MHz Clock
    always #7 clk_b = ~clk_b; // etwas asynchron

    // Reset
    logic rst_n;

    // Simulation Counter
    logic [7:0] sim_count_write;
    logic [7:0] sim_count_read;

    // === Wires ===

    // Single_Buffer Wires
    logic [$clog2(ADDRESS_NUMBER_B)-1:0] output_addresses_common;
    logic [BLOCK_DATA_WIDTH_B-1:0] buffer_out_data         [DATA_COUNT-1:0];

    // Output-Port Output
    logic [DATA_COUNT*BLOCK_DATA_WIDTH_B-1:0] output_data_flat;

    // === Inputs to Input_Port ===
    logic [$clog2(ADDRESS_NUMBER_A)-1:0] in_address;
    logic [(BANK_COUNT*BLOCK_COUNT)*BLOCK_DATA_WIDTH_A-1:0] in_data_flat;

    // === Inputs to Output_Port ===
    logic [$clog2(ADDRESS_NUMBER_B)-1:0] out_address;


    logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_B-1:0] buffer_out_data_flat;


    logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_A)-1:0] input_addresses_flat;
    logic [BANK_COUNT*BLOCK_COUNT*BLOCK_DATA_WIDTH_A-1:0]       input_data_flat;



    logic [BANK_COUNT*BLOCK_COUNT*$clog2(ADDRESS_NUMBER_B)-1:0] output_addresses_flat;

    always_comb begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            // Output_addresses_flat must be filed with output_addresses_common
            output_addresses_flat[i*$clog2(ADDRESS_NUMBER_B) +: $clog2(ADDRESS_NUMBER_B)] = output_addresses_common;
        end
    end



    // === DUT Instanzen ===

    // 1. Input_Port
    Input_Port #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A)
    ) input_port_inst (
        .I_address(in_address),
        .I_data_flat(in_data_flat),
        .O_addresses_flat(input_addresses_flat),
        .O_data_flat(input_data_flat)
    );

    // 2. Single_Buffer
    Single_Buffer #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_A(BLOCK_DATA_WIDTH_A),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) buffer_inst (
        .I_clka(clk_a),
        .I_cea(1'b1),
        .I_oce(1'b1),
        .I_reseta(~rst_n),
        .I_ada_flat(input_addresses_flat),
        .I_din_flat(input_data_flat),
        .I_clkb(clk_b),
        .I_ceb(1'b1),
        .I_resetb(~rst_n),
        .I_adb_flat(output_addresses_flat),
        .O_dout_flat(buffer_out_data_flat)
    );

    // 3. Output_Port
    Output_Port #(
        .BYTES_PER_BLOCK(BYTES_PER_BLOCK),
        .BANK_COUNT(BANK_COUNT),
        .BLOCK_COUNT(BLOCK_COUNT),
        .BLOCK_DATA_WIDTH_B(BLOCK_DATA_WIDTH_B)
    ) output_port_inst (
        .I_address(out_address),
        .O_data_flat(output_data_flat),
        .O_addresses_common(output_addresses_common),
        .I_data(buffer_out_data)
    );

    always_comb begin
        for (int i = 0; i < DATA_COUNT; i++) begin
            buffer_out_data[i] = buffer_out_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B];
        end
    end

    // === Initialisieren ===
    initial begin
        rst_n = 0;
        clk_a = 0;
        clk_b = 0;
        sim_count_write = 0;
        sim_count_read = 0;
        #20;
        rst_n = 1;

        #2000;
        $finish; // Simulation beenden
    end

    // Eingabe-Zähler
    always_ff @(posedge clk_a) begin
        if (rst_n) begin
            in_address <= sim_count_write;
            for (int i = 0; i < DATA_COUNT; i++) begin
                in_data_flat[i*BLOCK_DATA_WIDTH_A +: BLOCK_DATA_WIDTH_A] <= sim_count_write + i;
            end
            sim_count_write <= sim_count_write + 1;
        end
    end

    // Ausgabe-Zähler mit Verzögerung starten
    always_ff @(posedge clk_b) begin
        if (rst_n) begin
            if (sim_count_write > 10) begin
                out_address <= sim_count_read;
                sim_count_read <= sim_count_read + 1;
            end else begin
                out_address <= 0;
            end
        end
    end

    // Checker Logik
    always @(posedge clk_b) begin
        if (rst_n && sim_count_write > 10) begin
            for (int i = 0; i < DATA_COUNT; i++) begin
                logic [BLOCK_DATA_WIDTH_B-1:0] expected_data;
                expected_data = (sim_count_read - 1) + i;
                if (output_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B] !== expected_data[7:0]) begin
                    $display("Fehler bei Block %0d: Erwartet %0d, Gefunden %0d (Zeit %0t)", 
                        i, expected_data[7:0], output_data_flat[i*BLOCK_DATA_WIDTH_B +: BLOCK_DATA_WIDTH_B], $time);
                end
            end
        end
    end


    initial begin
        $dumpfile("Input_Buffer_Output_tb.vcd");
        $dumpvars(0, Input_Buffer_Output_tb);
    end


endmodule
