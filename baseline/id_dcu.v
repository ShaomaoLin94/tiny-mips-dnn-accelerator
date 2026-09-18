module id_dcu #(
	parameter R_TYPE = 6'd0,
	parameter ADD = 6'd32,
	parameter SUB = 6'd34,
	parameter AND = 6'd36,
	parameter OR = 6'd37,
	parameter SLT = 6'd42,
	parameter ADDI = 6'd8,
	parameter LW = 6'd35,
	parameter SW = 6'd43,
	parameter BEQ = 6'd4,
	parameter BNE = 6'd5,
	parameter J = 6'd2,
	parameter LWC1 = 6'd49,
	parameter SWC1 = 6'd57,
	parameter F_R_TYPE = 6'd17,
	parameter ADD_S = 6'd0,
	parameter MUL_S = 6'd2
)
(
    clk,
	rstn,
    rs_addr,
    rs_data,
    rt_addr,
    rt_data,
	fp_rs_addr,
    fp_rs_data,
    fp_rt_addr,
    fp_rt_data,
	fetch_pc,
	instr,
	fp_operation_dx,
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
	mem_data_fp
);
input			  		   clk;
input			  		   rstn;
input               [31:0] instr;
input               [31:0] fetch_pc;
output reg          	   fp_operation_dx;
output reg          	   mem_to_reg_dx;
output reg          	   reg_write_dx;
output reg          	   mem_read_dx;
output reg          	   mem_write_dx;
output reg          	   branch_dx;
output reg          	   jump_dx;
output reg 			 [3:0] alu_ctrl;
output reg          [31:0] jump_addr_dx;
output reg          [31:0] pc_dx;
output reg          [31:0] alu_src1;
output reg          [31:0] alu_src2;
output reg          [31:0] alu_src1_fp;
output reg          [31:0] alu_src2_fp;
output reg 			[15:0] imm;
output reg 			 [4:0] rd_addr_dx;
output reg 			[31:0] mem_data;
output reg 			[31:0] mem_data_fp;

input               [31:0] rs_data;
input               [31:0] rt_data;

output 				 [4:0] rs_addr;
output 				 [4:0] rt_addr;
input               [31:0] fp_rs_data;
input               [31:0] fp_rt_data;
output 				 [4:0] fp_rs_addr;
output 				 [4:0] fp_rt_addr;

reg 					   fp_ls;


assign rs_addr = instr[25:21];
assign rt_addr = instr[20:16];

assign fp_rs_addr = instr[15:11];
assign fp_rt_addr = instr[20:16];

always @(*) begin
	case(instr[31:26])
		LWC1:
			fp_ls 		<= 1'b1;
		SWC1:
			fp_ls 		<= 1'b1;
		default: 
			fp_ls 		<= 1'b0;
	endcase
end

always @(posedge clk or negedge rstn)
begin
	if(!rstn) begin
		alu_src1 		<= 32'b0;	
		alu_src1_fp	 	<= 32'b0;	
		mem_data 		<= 32'b0;
		mem_data_fp 	<= 32'b0;
		imm 			<= 16'b0;
	    pc_dx			<= 32'b0;
		jump_dx 		<= 1'b0;
		jump_addr_dx 	<= 32'b0;
	end else begin
		alu_src1 		<= rs_data;
		alu_src1_fp 	<= fp_ls ? rs_data : fp_rs_data;
		mem_data 		<= rt_data;
		mem_data_fp 	<= fp_rt_data;
		imm 			<= instr[15:0];
	    pc_dx 			<= fetch_pc;
		jump_dx			<= (instr[31:26]==6'd2) ? 1'b1 : 1'b0;
		jump_addr_dx	<= {fetch_pc[31:28], instr[25:0], 2'b0};
	end
end

//instruction decoding
always @(posedge clk or negedge rstn)
begin
   if(!rstn) begin
		alu_src2 		<= 32'b0;
		alu_src2_fp		<= 32'b0;
		mem_to_reg_dx	<= 1'b0;
		reg_write_dx	<= 1'b0;
		mem_read_dx 	<= 1'b0;
		mem_write_dx	<= 1'b0;
		branch_dx  		<= 1'b0;
		alu_ctrl		<= 4'b0;
		rd_addr_dx 		<=5'b0;
		fp_operation_dx <= 1'b0;
		
   end else begin
   		case( instr[31:26] )
		R_TYPE:
			begin
				alu_src2 		 <= rt_data;
				rd_addr_dx 		 <= instr[15:11];
				mem_to_reg_dx	 <= 1'b0;
				reg_write_dx	 <= 1'b1;
				mem_read_dx 	 <= 1'b0;
				mem_write_dx	 <= 1'b0;
				branch_dx  		 <= 1'b0;
			    case(instr[5:0])
					AND:
						alu_ctrl <= 4'd0;
					OR:
						alu_ctrl <= 4'd1;
					ADD:
				        alu_ctrl <= 4'd2;
					SUB:
						alu_ctrl <= 4'd6;
					SLT:  
						alu_ctrl <= 4'd7;
		    	endcase
				fp_operation_dx  <= 1'b0;
			end
		ADDI:  begin
				alu_src2 		 <= {{16{instr[15]}}, instr[15:0]};
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b0;
			    reg_write_dx	 <= 1'b1;
			    mem_read_dx 	 <= 1'b0;
			    mem_write_dx	 <= 1'b0;
			    branch_dx  		 <= 1'b0;
			    alu_ctrl  		 <= 4'd2;
			    fp_operation_dx  <= 1'b0;
		 	end
		LW:  begin
				alu_src2 		 <= {{16{instr[15]}}, instr[15:0]};
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b1;
			    reg_write_dx	 <= 1'b1;
			    mem_read_dx  	 <= 1'b1;
			    mem_write_dx	 <= 1'b0;
			    branch_dx  	     <= 1'b0;
			    alu_ctrl     	 <= 4'd2;
			    fp_operation_dx  <= 1'b0;
		 	end
		SW:  begin
				alu_src2 		 <= {{16{instr[15]}}, instr[15:0]};
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b0;
			    reg_write_dx	 <= 1'b0;
			    mem_read_dx 	 <= 1'b0;
			    mem_write_dx	 <= 1'b1;
			    branch_dx  	 	 <= 1'b0;
			    alu_ctrl  		 <= 4'd2;
				fp_operation_dx  <= 1'b0;
		 	end
		BEQ:   begin
				alu_src2 		 <= rt_data;
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b0;
			    reg_write_dx	 <= 1'b0;
			    mem_read_dx 	 <= 1'b0;
			    mem_write_dx	 <= 1'b0;
			    branch_dx 	  	 <= 1'b1;
			    alu_ctrl  	     <= 4'd5;
				fp_operation_dx  <= 1'b0;
			end
		BNE:   begin
			    alu_src2 		 <= rt_data;
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b0;
			    reg_write_dx	 <= 1'b0;
			    mem_read_dx 	 <= 1'b0;
			    mem_write_dx	 <= 1'b0;
			    branch_dx  		 <= 1'b1;
			    alu_ctrl  	     <= 4'd5;
				fp_operation_dx  <= 1'b0;
			end
		J: begin 
			    alu_src2 		 <= rt_data;
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b0;
			    reg_write_dx	 <= 1'b0;
			    mem_read_dx 	 <= 1'b0;
			    mem_write_dx	 <= 1'b0;
			    branch_dx  	 	 <= 1'b0;
			    alu_ctrl  		 <= 4'd5;
				fp_operation_dx  <= 1'b0;
			end
		LWC1:  begin
				alu_src2_fp		 <= {{16{instr[15]}}, instr[15:0]};
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b1;
			    reg_write_dx	 <= 1'b1;
			    mem_read_dx 	 <= 1'b1;
			    mem_write_dx	 <= 1'b0;
			    branch_dx  	 	 <= 1'b0;
			    alu_ctrl  		 <= 4'd8;
				fp_operation_dx  <= 1'b1;
		 	end
		SWC1:  begin
				alu_src2_fp		 <= {{16{instr[15]}}, instr[15:0]};
			    rd_addr_dx 		 <= instr[20:16];
			    mem_to_reg_dx	 <= 1'b0;
			    reg_write_dx	 <= 1'b0;
			    mem_read_dx 	 <= 1'b0;
			    mem_write_dx	 <= 1'b1;
			    branch_dx  		 <= 1'b0;
			    alu_ctrl  	 	 <= 4'd8;
				fp_operation_dx  <= 1'b1;
		 	end
		F_R_TYPE:  begin
				alu_src2_fp		 <= fp_rt_data;
			    rd_addr_dx 		 <= instr[10:6];
			    mem_to_reg_dx	 <= 1'b0;
			    reg_write_dx	 <= 1'b1;
			    mem_read_dx 	 <= 1'b0;
			    mem_write_dx	 <= 1'b0;
			    branch_dx  		 <= 1'b0;
			    case(instr[5:0])
					ADD_S:
						alu_ctrl <= 4'd9;
					MUL_S:
						alu_ctrl <= 4'd10;
				endcase
				fp_operation_dx  <= 1'b1;
		 	end
			default: begin
				alu_src2_fp		 <= alu_src2_fp;
			    rd_addr_dx 		 <= rd_addr_dx;
			    mem_to_reg_dx	 <= mem_to_reg_dx;
			    reg_write_dx	 <= reg_write_dx;
			    mem_read_dx 	 <= mem_read_dx;
			    mem_write_dx	 <= mem_write_dx;
			    branch_dx  		 <= branch_dx;
			    alu_ctrl  	 	 <= alu_ctrl;
				fp_operation_dx  <= fp_operation_dx;
			end
		endcase
   end
end
endmodule