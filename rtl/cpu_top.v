`timescale 1ns/1ps
module cpu_top(
    input clk, rstn,
    input [4:0] ahb_rf_addr,
    output [31:0] ahb_rf_data,
    input [10:0] ahb_im_addr,
    input [31:0] ahb_im_din,
    input ahb_im_wen,
    output [31:0] ahb_im_dout,
    input [10:0] ahb_dm_addr,
    input [31:0] ahb_dm_din,
    input ahb_dm_wen,
    output [31:0] ahb_dm_dout
);
    wire [31:0] fetch_pc, fetch_instr, pc4_fd;
    wire valid_fd, stall, redirect, redirect_ex;
    wire [31:0] redirect_pc;
    wire [4:0] src_a_id, src_b_id, src_c_id, dest_id;
    wire use_a_id, use_b_id, use_c_id, fp_a_id, fp_b_id, fp_c_id;
    wire write_id, load_id, store_id, dest_fp_id, use_imm_id;
    wire [3:0] op_id;
    wire [31:0] imm_id, data_a_id, data_b_id, data_c_id;

    reg valid_dx, valid_xm, valid_mw;
    reg [31:0] instr_dx, pc4_dx, imm_dx, a_dx, b_dx, c_dx;
    reg [4:0] src_a_dx, src_b_dx, src_c_dx, rd_addr_dx;
    reg use_a_dx, use_b_dx, use_c_dx, fp_a_dx, fp_b_dx, fp_c_dx;
    reg reg_write_dx, mem_read_dx, mem_write_dx, fp_operation_dx, use_imm_dx;
    reg [3:0] op_dx;
    reg [31:0] result_xm, store_data_xm;
    reg [4:0] rd_addr_xm;
    reg reg_write_xm, mem_read_xm, mem_write_xm, fp_operation_xm;
    reg [31:0] result_mw;
    reg [4:0] rd_addr_mw;
    reg reg_write_mw, mem_to_reg_mw, fp_operation_mw;
    wire [31:0] load_data_mw, wb_data, ex_a, ex_b, ex_c, ex_result;
    wire wb_write = valid_mw && reg_write_mw;
    assign wb_data = mem_to_reg_mw ? load_data_mw : result_mw;
    assign redirect = valid_dx && redirect_ex;

    if_pipe IF(.clk(clk), .rstn(rstn), .stall(stall), .redirect(redirect),
        .redirect_pc(redirect_pc), .fetch_pc(fetch_pc), .pc4_fd(pc4_fd),
        .fetch_instr(fetch_instr), .valid_fd(valid_fd),
        .ahb_im_addr(ahb_im_addr), .ahb_im_din(ahb_im_din),
        .ahb_im_wen(ahb_im_wen), .ahb_im_dout(ahb_im_dout));

    id_dcu DEC(.instr(fetch_instr),
        .src_a(src_a_id), .src_b(src_b_id), .src_c(src_c_id), .dest(dest_id),
        .use_a(use_a_id), .use_b(use_b_id), .use_c(use_c_id),
        .fp_a(fp_a_id), .fp_b(fp_b_id), .fp_c(fp_c_id), .dest_fp(dest_fp_id),
        .reg_write(write_id), .mem_read(load_id), .mem_write(store_id),
        .use_imm(use_imm_id), .alu_op(op_id), .immediate(imm_id));

    id_pipe ID(
        .clk(clk), .rstn(rstn), .write_en(wb_write), .write_fp(fp_operation_mw),
        .src_a(src_a_id), .src_b(src_b_id), .src_c(src_c_id),
        .fp_a(fp_a_id), .fp_b(fp_b_id), .fp_c(fp_c_id),
        .write_addr(rd_addr_mw), .write_data(wb_data),
        .data_a(data_a_id), .data_b(data_b_id), .data_c(data_c_id),
        .ahb_rf_addr(ahb_rf_addr), .ahb_rf_data(ahb_rf_data));

    hazard_unit HAZARD(
        .valid_id(valid_fd), .src_a(src_a_id), .src_b(src_b_id), .src_c(src_c_id),
        .use_a(use_a_id), .use_b(use_b_id), .use_c(use_c_id),
        .fp_a(fp_a_id), .fp_b(fp_b_id), .fp_c(fp_c_id),
        .dest_dx(rd_addr_dx), .write_dx(valid_dx && reg_write_dx),
        .fp_dx(fp_operation_dx), .load_dx(mem_read_dx), .stall(stall));

    forwarding_unit FWD_A(
        .src(src_a_dx), .src_fp(fp_a_dx), .src_used(use_a_dx), .original_data(a_dx),
        .dest_xm(rd_addr_xm), .dest_mw(rd_addr_mw),
        .write_xm(valid_xm && reg_write_xm), .write_mw(wb_write),
        .fp_xm(fp_operation_xm), .fp_mw(fp_operation_mw), .load_xm(mem_read_xm),
        .result_xm(result_xm), .result_mw(wb_data), .data(ex_a));
    forwarding_unit FWD_B(
        .src(src_b_dx), .src_fp(fp_b_dx), .src_used(use_b_dx), .original_data(b_dx),
        .dest_xm(rd_addr_xm), .dest_mw(rd_addr_mw),
        .write_xm(valid_xm && reg_write_xm), .write_mw(wb_write),
        .fp_xm(fp_operation_xm), .fp_mw(fp_operation_mw), .load_xm(mem_read_xm),
        .result_xm(result_xm), .result_mw(wb_data), .data(ex_b));
    forwarding_unit FWD_C(
        .src(src_c_dx), .src_fp(fp_c_dx), .src_used(use_c_dx), .original_data(c_dx),
        .dest_xm(rd_addr_xm), .dest_mw(rd_addr_mw),
        .write_xm(valid_xm && reg_write_xm), .write_mw(wb_write),
        .fp_xm(fp_operation_xm), .fp_mw(fp_operation_mw), .load_xm(mem_read_xm),
        .result_xm(result_xm), .result_mw(wb_data), .data(ex_c));

    ex_pipe EXE(.alu_op(op_dx), .a(ex_a), .b(ex_b), .c(ex_c),
        .immediate(imm_dx), .pc4(pc4_dx), .instr(instr_dx), .use_imm(use_imm_dx),
        .result(ex_result), .redirect(redirect_ex), .redirect_pc(redirect_pc));

    mem_pipe MEM(.clk(clk), .rstn(rstn), .valid_xm(valid_xm), .mem_write_xm(mem_write_xm),
        .address_xm(result_xm), .store_data_xm(store_data_xm),
        .ahb_dm_addr(ahb_dm_addr), .ahb_dm_din(ahb_dm_din), .ahb_dm_wen(ahb_dm_wen),
        .ahb_dm_dout(ahb_dm_dout), .load_data_mw(load_data_mw));

    // ID/EX：stall 只停 IF/ID，EX 放 bubble，前面的 load 才能繼續走。
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_dx <= 0;
            instr_dx <= 0; pc4_dx <= 0; imm_dx <= 0;
            a_dx <= 0; b_dx <= 0; c_dx <= 0;
            src_a_dx <= 0; src_b_dx <= 0; src_c_dx <= 0; rd_addr_dx <= 0;
            use_a_dx <= 0; use_b_dx <= 0; use_c_dx <= 0;
            fp_a_dx <= 0; fp_b_dx <= 0; fp_c_dx <= 0;
            reg_write_dx <= 0; mem_read_dx <= 0; mem_write_dx <= 0;
            fp_operation_dx <= 0; use_imm_dx <= 0; op_dx <= 0;
        end else begin
            valid_dx <= valid_fd && !stall && !redirect;
            instr_dx <= fetch_instr; pc4_dx <= pc4_fd; imm_dx <= imm_id;
            a_dx <= data_a_id; b_dx <= data_b_id; c_dx <= data_c_id;
            src_a_dx <= src_a_id; src_b_dx <= src_b_id; src_c_dx <= src_c_id;
            rd_addr_dx <= dest_id;
            use_a_dx <= use_a_id; use_b_dx <= use_b_id; use_c_dx <= use_c_id;
            fp_a_dx <= fp_a_id; fp_b_dx <= fp_b_id; fp_c_dx <= fp_c_id;
            reg_write_dx <= write_id; mem_read_dx <= load_id; mem_write_dx <= store_id;
            fp_operation_dx <= dest_fp_id; use_imm_dx <= use_imm_id; op_dx <= op_id;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_xm <= 0; valid_mw <= 0;
            result_xm <= 0; store_data_xm <= 0;
            rd_addr_xm <= 0; reg_write_xm <= 0; mem_read_xm <= 0;
            mem_write_xm <= 0; fp_operation_xm <= 0;
            result_mw <= 0; rd_addr_mw <= 0;
            reg_write_mw <= 0; mem_to_reg_mw <= 0; fp_operation_mw <= 0;
        end else begin
            valid_xm <= valid_dx;
            result_xm <= ex_result; store_data_xm <= ex_b;
            rd_addr_xm <= rd_addr_dx; reg_write_xm <= reg_write_dx;
            mem_read_xm <= mem_read_dx; mem_write_xm <= mem_write_dx;
            fp_operation_xm <= fp_operation_dx;
            valid_mw <= valid_xm;
            result_mw <= result_xm;
            rd_addr_mw <= rd_addr_xm; reg_write_mw <= reg_write_xm;
            mem_to_reg_mw <= mem_read_xm; fp_operation_mw <= fp_operation_xm;
        end
    end
endmodule
