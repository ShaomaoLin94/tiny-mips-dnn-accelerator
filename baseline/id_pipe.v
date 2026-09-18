module id_pipe(
	clk,
	rstn,
	fetch_pc,
	fetch_instr,
	mem_to_reg_mw,
	reg_write_mw,
	rd_addr_mw,
	mem_data_to_reg,
	mem_data_to_reg_fp,
	alu_out_mw,
	alu_out_fp_mw,
	fp_operation_mw,
	mem_to_reg_dx,
	reg_write_dx,
	mem_read_dx,
	mem_write_dx,
	branch_dx,
	jump_dx,
	alu_ctrl,
	jump_addr_dx,
	pc_dx,
	alu_src1,
	alu_src2,
	alu_src1_fp,
	alu_src2_fp,
	imm,
	rd_addr_dx,
	mem_data,
	mem_data_fp,
	fp_operation_dx,
	ahb_rf_addr,
	ahb_rf_data
);
input			  		   clk;
input			  		   rstn;
input			  		   mem_to_reg_mw;
input			  		   reg_write_mw;
input			  		   fp_operation_mw;
input 				[31:0] fetch_instr;
input 				[31:0] fetch_pc;
input 				[31:0] mem_data_to_reg;
input 				[31:0] mem_data_to_reg_fp;
input 				[31:0] alu_out_mw;
input 				[31:0] alu_out_fp_mw;
input 				 [4:0] rd_addr_mw;
output			  		   mem_to_reg_dx;
output			  		   reg_write_dx;
output			  		   mem_read_dx;
output			  		   mem_write_dx;
output			  		   branch_dx;
output			  		   jump_dx;
output 				 [3:0] alu_ctrl;
output 				[31:0] jump_addr_dx;
output 				[31:0] pc_dx;
output 				[31:0] alu_src1;
output 				[31:0] alu_src2;
output 				[31:0] alu_src1_fp;
output 				[31:0] alu_src2_fp;
output 				[15:0] imm;
output 				 [4:0] rd_addr_dx;
output 				[31:0] mem_data;
output 				[31:0] mem_data_fp;
output 					   fp_operation_dx;
input 				 [4:0] ahb_rf_addr;
output 				[31:0] ahb_rf_data;


reg 				[31:0] REG_F [0:31];
integer 				   i;
wire				[31:0] rs_data;
wire				[31:0] rt_data;
wire				[31:0] rd_data;
wire				 [4:0] rs_addr;
wire				 [4:0] rt_addr;
wire				 [4:0] rd_addr;
wire				[31:0] fp_rs_data;
wire				[31:0] fp_rt_data;
wire				[31:0] fp_rd_data;
wire				 [4:0] fp_rs_addr;
wire				 [4:0] fp_rt_addr;
wire				 [4:0] fp_srd_addr;

rf rf(
	.clk				(clk				),
    .rstn				(rstn				),
    .rs_addr			(rs_addr			),
    .rs_data			(rs_data			),
    .rt_addr			(rt_addr			),
    .rt_data			(rt_data			),
    .rd_addr			(rd_addr_mw			),
    // .rd_data			(rd_data			),
	.fp_operation_mw	(fp_operation_mw	),
    .reg_write_mw		(reg_write_mw		),
    .mem_to_reg_mw		(mem_to_reg_mw		),
    .mem_data_to_reg	(mem_data_to_reg	),
    .alu_out_mw			(alu_out_mw			),
	.ahb_rf_addr		(ahb_rf_addr		),
	.ahb_rf_data		(ahb_rf_data		)
);

fp_rf fp_rf(
    .clk				(clk				),
    .rstn				(rstn				),
    .fp_rs_addr			(fp_rs_addr			),
    .fp_rs_data			(fp_rs_data			),
    .fp_rt_addr			(fp_rt_addr			),
    .fp_rt_data			(fp_rt_data			),
    .fp_rd_addr			(rd_addr_mw			),
    // .rd_data			(rd_data			),
	.fp_operation_mw	(fp_operation_mw	),
    .reg_write_mw		(reg_write_mw		),
    .mem_to_reg_mw		(mem_to_reg_mw		),
    .mem_data_to_reg_fp	(mem_data_to_reg_fp	),
    .alu_out_fp_mw		(alu_out_fp_mw		)
);

id_dcu id_dcu(
	.clk				(clk				),
	.rstn				(rstn				),
    .rs_addr			(rs_addr			),
    .rs_data			(rs_data			),
    .rt_addr			(rt_addr			),
    .rt_data			(rt_data			),
	.fp_rs_addr			(fp_rs_addr			),
    .fp_rs_data			(fp_rs_data			),
    .fp_rt_addr			(fp_rt_addr			),
    .fp_rt_data			(fp_rt_data			),
	.fetch_pc			(fetch_pc			),
	.instr				(fetch_instr		),
	.fp_operation_dx	(fp_operation_dx	),
	.mem_to_reg_dx		(mem_to_reg_dx		),
	.reg_write_dx		(reg_write_dx		),
	.mem_read_dx		(mem_read_dx		),
	.mem_write_dx		(mem_write_dx		),
	.branch_dx			(branch_dx			),
	.jump_dx			(jump_dx			),
	.alu_ctrl			(alu_ctrl			),
	.jump_addr_dx		(jump_addr_dx		),
	.pc_dx				(pc_dx				),
	.alu_src1			(alu_src1			),
	.alu_src2			(alu_src2			),
	.alu_src1_fp		(alu_src1_fp		),
	.alu_src2_fp		(alu_src2_fp		),
	.imm				(imm				),
	.rd_addr_dx			(rd_addr_dx			),
	.mem_data			(mem_data			),
	.mem_data_fp		(mem_data_fp		)
);

endmodule