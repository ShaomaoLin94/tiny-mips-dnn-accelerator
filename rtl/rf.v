module rf(
    input clk, rstn, write_en,
    input [4:0] addr_a, addr_b, addr_c, write_addr, ahb_rf_addr,
    input [31:0] write_data,
    output [31:0] data_a, data_b, data_c, ahb_rf_data
);
    reg [31:0] REG_I [0:31];
    integer i;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 32; i = i + 1) REG_I[i] <= 0;
        end else if (write_en && write_addr != 0)
            REG_I[write_addr] <= write_data;
    end
    // WB 和 ID 同一拍時，ID 要直接讀到這次寫回的值。
    assign data_a = (addr_a == 0) ? 0 :
        (write_en && write_addr == addr_a) ? write_data : REG_I[addr_a];
    assign data_b = (addr_b == 0) ? 0 :
        (write_en && write_addr == addr_b) ? write_data : REG_I[addr_b];
    assign data_c = (addr_c == 0) ? 0 :
        (write_en && write_addr == addr_c) ? write_data : REG_I[addr_c];
    assign ahb_rf_data = REG_I[ahb_rf_addr];
endmodule
