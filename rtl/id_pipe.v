`timescale 1ns/1ps
module id_pipe(
    input clk, rstn, write_en, write_fp,
    input [4:0] src_a, src_b, src_c, write_addr, ahb_rf_addr,
    input fp_a, fp_b, fp_c,
    input [31:0] write_data,
    output [31:0] data_a, data_b, data_c, ahb_rf_data
);
    wire [31:0] ia, ib, ic, fa, fb, fc;
    rf rf(
        .clk(clk), .rstn(rstn), .write_en(write_en && !write_fp),
        .addr_a(src_a), .addr_b(src_b), .addr_c(src_c),
        .write_addr(write_addr), .write_data(write_data),
        .data_a(ia), .data_b(ib), .data_c(ic),
        .ahb_rf_addr(ahb_rf_addr), .ahb_rf_data(ahb_rf_data));
    fp_rf fp_rf(
        .clk(clk), .rstn(rstn), .write_en(write_en && write_fp),
        .addr_a(src_a), .addr_b(src_b), .addr_c(src_c),
        .write_addr(write_addr), .write_data(write_data),
        .data_a(fa), .data_b(fb), .data_c(fc));
    assign data_a = fp_a ? fa : ia;
    assign data_b = fp_b ? fb : ib;
    assign data_c = fp_c ? fc : ic;
endmodule
