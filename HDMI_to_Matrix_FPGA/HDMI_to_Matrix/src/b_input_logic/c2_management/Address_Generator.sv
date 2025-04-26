module Address_Generator #(
    parameter int ADDRESS_BITS = 8
) (
    input  logic                          I_rst_n,
    input  logic                          I_clk,
    input  logic                          I_address_up,
    input  logic                          I_address_reset,
    
    output logic [ADDRESS_BITS-1:0]       O_address
);
    logic address_up_d, address_reset_d;

    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            address_up_d <= 1'b0;
            address_reset_d <= 1'b0;
        end else begin
            address_up_d <= I_address_up;
            address_reset_d <= I_address_reset;
        end
    end

    logic address_up_posedge;
    logic address_reset_posedge;

    assign address_up_posedge = ~address_up_d & I_address_up;
    assign address_reset_posedge = ~address_reset_d & I_address_reset;




    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            O_address <= '0;
        end else if (address_reset_posedge) begin
            O_address <= '0;
        end else if (address_up_posedge) begin
            O_address <= O_address + 1'b1;
        end
    end

endmodule