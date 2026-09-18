`include "isa.vh"

module id_dcu(
    input [31:0] instr,
    output reg [4:0] src_a, src_b, src_c, dest,
    output reg use_a, use_b, use_c,
    output reg fp_a, fp_b, fp_c, dest_fp,
    output reg reg_write, mem_read, mem_write, use_imm,
    output reg [3:0] alu_op,
    output [31:0] immediate
);
    assign immediate = {{16{instr[15]}}, instr[15:0]};

    always @* begin
        // 先給預設值，避免不支援的指令沿用上一筆控制訊號。
        src_a = instr[25:21];
        src_b = instr[20:16];
        src_c = instr[10:6];
        dest = instr[15:11];
        use_a = 0; use_b = 0; use_c = 0;
        fp_a = 0; fp_b = 0; fp_c = 0; dest_fp = 0;
        reg_write = 0; mem_read = 0; mem_write = 0; use_imm = 0;
        alu_op = `ALU_ADD;
        case (instr[31:26])
            6'h00: begin
                use_a = 1; use_b = 1; reg_write = 1;
                case (instr[5:0])
                    6'h20: alu_op = `ALU_ADD;
                    6'h22: alu_op = `ALU_SUB;
                    6'h24: alu_op = `ALU_AND;
                    6'h25: alu_op = `ALU_OR;
                    6'h2a: alu_op = `ALU_SLT;
                    default: begin
                        reg_write = 0;
                        use_a = 0;
                        use_b = 0;
                    end
                endcase
                if (instr == 0) begin
                    reg_write = 0; use_a = 0; use_b = 0;
                end
            end
            6'h08: begin // addi
                use_a = 1; use_imm = 1; reg_write = 1;
                dest = instr[20:16];
            end
            6'h23, 6'h31: begin // lw / lwc1 的 base 都是整數暫存器
                use_a = 1; use_imm = 1; reg_write = 1; mem_read = 1;
                dest = instr[20:16];
                dest_fp = (instr[31:26] == 6'h31);
            end
            6'h2b, 6'h39: begin
                use_a = 1; use_b = 1; use_imm = 1; mem_write = 1;
                fp_b = (instr[31:26] == 6'h39);
            end
            6'h04, 6'h05: begin
                use_a = 1; use_b = 1;
                alu_op = (instr[31:26] == 6'h04) ? `OP_BEQ : `OP_BNE;
            end
            6'h02: alu_op = `OP_J;
            6'h11: begin // COP1 single precision
                src_a = instr[15:11];
                dest = instr[10:6];
                if (instr[25:21] == 5'h10) begin
                    use_a = 1; use_b = 1; fp_a = 1; fp_b = 1;
                    dest_fp = 1; reg_write = 1;
                    case (instr[5:0])
                        6'h00: alu_op = `FP_ADD;
                        6'h02: alu_op = `FP_MUL;
                        default: begin
                            reg_write = 0;
                            use_a = 0;
                            use_b = 0;
                        end
                    endcase
                end
            end
            6'h1c: begin
                if (instr[5:0] == 6'h02 && instr[10:6] == 0) begin
                    use_a = 1; use_b = 1; reg_write = 1;
                    alu_op = `ALU_MUL;
                end else if (instr[5:0] == 6'h3e && instr[25:21] == 0) begin
                    // 自訂 mac.s fd, fs, ft：fd = fd + fs * ft
                    src_a = instr[15:11];
                    dest = instr[10:6];
                    use_a = 1; use_b = 1; use_c = 1;
                    fp_a = 1; fp_b = 1; fp_c = 1;
                    dest_fp = 1; reg_write = 1;
                    alu_op = `FP_MAC;
                end
            end
            default: begin end
        endcase
    end
endmodule
