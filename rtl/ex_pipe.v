`timescale 1ns/1ps
`include "isa.vh"

module ex_pipe(
    input [3:0] alu_op,
    input [31:0] a, b, c, immediate, pc4, instr,
    input use_imm,
    output reg [31:0] result,
    output reg redirect,
    output reg [31:0] redirect_pc
);
    wire [31:0] operand_b = use_imm ? immediate : b;
    wire [31:0] fp_product, fp_sum;
    // MAC 沿用 mul.s / add.s 的兩次捨入，不是 fused multiply-add。
    wire [31:0] add_a = (alu_op == `FP_MAC) ? c : a;
    wire [31:0] add_b = (alu_op == `FP_MAC) ? fp_product : b;

    fp_mul mul_unit(.s_axis_a_tvalid(1'b1), .s_axis_a_tdata(a),
        .s_axis_b_tvalid(1'b1), .s_axis_b_tdata(b),
        .m_axis_result_tvalid(), .m_axis_result_tdata(fp_product));
    fp_add add_unit(.s_axis_a_tvalid(1'b1), .s_axis_a_tdata(add_a),
        .s_axis_b_tvalid(1'b1), .s_axis_b_tdata(add_b),
        .m_axis_result_tvalid(), .m_axis_result_tdata(fp_sum));

    always @* begin
        result = 0;
        redirect = 0;
        redirect_pc = pc4 + (immediate << 2);
        case (alu_op)
            `ALU_AND: result = a & operand_b;
            `ALU_OR:  result = a | operand_b;
            `ALU_ADD: result = a + operand_b;
            `ALU_SUB: result = a - operand_b;
            `ALU_SLT: result = {31'd0, ($signed(a) < $signed(operand_b))};
            `ALU_MUL: result = a * operand_b;
            `FP_ADD, `FP_MAC: result = fp_sum;
            `FP_MUL: result = fp_product;
            `OP_BEQ: redirect = (a == b);
            `OP_BNE: redirect = (a != b);
            `OP_J: begin
                redirect = 1;
                redirect_pc = {pc4[31:28], instr[25:0], 2'b00};
            end
            default: result = 0;
        endcase
    end
endmodule
