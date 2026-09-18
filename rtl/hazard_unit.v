module hazard_unit(
    input valid_id,
    input [4:0] src_a, src_b, src_c, dest_dx,
    input use_a, use_b, use_c, fp_a, fp_b, fp_c,
    input write_dx, fp_dx, load_dx,
    output stall
);
    // Load 的資料到 MEM 才準備好，下一條指令若立刻使用就停一拍。
    wire valid_dest = fp_dx || (dest_dx != 0);
    wire hit_a = use_a && (fp_a == fp_dx) && (src_a == dest_dx);
    wire hit_b = use_b && (fp_b == fp_dx) && (src_b == dest_dx);
    wire hit_c = use_c && (fp_c == fp_dx) && (src_c == dest_dx);

    assign stall = valid_id && write_dx && load_dx && valid_dest &&
                   (hit_a || hit_b || hit_c);
endmodule
