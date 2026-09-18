module fp_rf(
    input clk, rstn, write_en,
    input [4:0] addr_a, addr_b, addr_c, write_addr,
    input [31:0] write_data,
    output [31:0] data_a, data_b, data_c
);
    reg [31:0] REG_F [0:31];
    integer i;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 32; i = i + 1) REG_F[i] <= 0;
        end else if (write_en) REG_F[write_addr] <= write_data;
    end
    // f0 是一般浮點暫存器，不能套用整數 r0 的判斷。
    assign data_a = (write_en && write_addr == addr_a) ? write_data : REG_F[addr_a];
    assign data_b = (write_en && write_addr == addr_b) ? write_data : REG_F[addr_b];
    assign data_c = (write_en && write_addr == addr_c) ? write_data : REG_F[addr_c];
endmodule
