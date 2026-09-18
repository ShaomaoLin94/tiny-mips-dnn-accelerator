`timescale 1ns/1ps
module forwarding_unit(
    input [4:0] src, dest_xm, dest_mw,
    input src_fp, src_used, write_xm, write_mw, fp_xm, fp_mw, load_xm,
    input [31:0] original_data, result_xm, result_mw,
    output reg [31:0] data
);
    always @* begin
        data = original_data;
        if (src_used && (src_fp || src != 0)) begin
            // EX/MEM 比 MEM/WB 新。Load 在這一級只有位址，不能拿來 forward。
            if (write_xm && src_fp == fp_xm && src == dest_xm) begin
                if (!load_xm) data = result_xm;
            end else if (write_mw && src_fp == fp_mw && src == dest_mw)
                data = result_mw;
        end
    end
endmodule
