`timescale 1ns/1ps

module hazard_tb;
    reg valid_id, use_a, use_b, use_c;
    reg fp_a, fp_b, fp_c, write_dx, fp_dx, load_dx;
    reg [4:0] src_a, src_b, src_c, dest_dx;
    wire stall;

    reg [4:0] src, dest_xm, dest_mw;
    reg src_fp, src_used, write_xm, write_mw, fp_xm, fp_mw, load_xm;
    reg [31:0] original_data, result_xm, result_mw;
    wire [31:0] forwarded_data;

    hazard_unit hazard(
        .valid_id(valid_id), .src_a(src_a), .src_b(src_b), .src_c(src_c),
        .dest_dx(dest_dx), .use_a(use_a), .use_b(use_b), .use_c(use_c),
        .fp_a(fp_a), .fp_b(fp_b), .fp_c(fp_c), .write_dx(write_dx),
        .fp_dx(fp_dx), .load_dx(load_dx), .stall(stall)
    );

    forwarding_unit forwarding(
        .src(src), .dest_xm(dest_xm), .dest_mw(dest_mw),
        .src_fp(src_fp), .src_used(src_used), .write_xm(write_xm),
        .write_mw(write_mw), .fp_xm(fp_xm), .fp_mw(fp_mw),
        .load_xm(load_xm), .original_data(original_data),
        .result_xm(result_xm), .result_mw(result_mw), .data(forwarded_data)
    );

    initial begin
        // load-use：下一條馬上使用 load 結果時，應該停一拍。
        valid_id = 1; use_a = 1; use_b = 0; use_c = 0;
        fp_a = 0; fp_b = 0; fp_c = 0;
        src_a = 5; src_b = 0; src_c = 0; dest_dx = 5;
        write_dx = 1; fp_dx = 0; load_dx = 1;
        #1;
        if (!stall) $fatal(1, "load-use stall was not generated");

        src_a = 6;
        #1;
        if (stall) $fatal(1, "unrelated instruction should not stall");

        // 一般 ALU 結果可直接從 EX/MEM forward。
        src = 5; dest_xm = 5; dest_mw = 5;
        src_fp = 0; src_used = 1; write_xm = 1; write_mw = 1;
        fp_xm = 0; fp_mw = 0; load_xm = 0;
        original_data = 32'h11111111;
        result_xm = 32'h22222222; result_mw = 32'h33333333;
        #1;
        if (forwarded_data !== 32'h22222222)
            $fatal(1, "EX/MEM forwarding has wrong priority");

        write_xm = 0;
        #1;
        if (forwarded_data !== 32'h33333333)
            $fatal(1, "MEM/WB forwarding failed");

        $display("PASS hazard: load-use stall and forwarding");
        $finish;
    end
endmodule
