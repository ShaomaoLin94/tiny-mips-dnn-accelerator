module ex_pipe(
	clk,
	rstn,
	mem_to_reg_dx,
	reg_write_dx,
	mem_read_dx,
	mem_write_dx,
	branch_dx,
	fp_operation_dx,
	alu_ctrl,
	pc_dx,
	alu_src1,
	alu_src2,
	alu_src1_fp,
	alu_src2_fp,
	imm,
	rd_addr_dx,
	mem_data_dx,
	mem_data_fp_dx,
	mem_to_reg_xm,
	reg_write_xm,
	mem_read_xm,
	mem_write_xm,
	branch_xm,
	alu_out_xm,
	alu_out_fp_xm,
	rd_addr_xm,
	mem_data_xm,
	mem_data_fp_xm,
	branch_addr_xm,
	fp_operation_xm
);

input			  			clk;
input			 			rstn;
input			 	 		mem_to_reg_dx;
input			 	  		reg_write_dx;
input			 	   		mem_read_dx;
input			 	  		mem_write_dx;
input			 	 	 	branch_dx;
input			   			fp_operation_dx;
input 			      [3:0] alu_ctrl;
input 			     [31:0] alu_src1;
input 			     [31:0] alu_src2;
input 			     [31:0] alu_src1_fp;
input 			     [31:0] alu_src2_fp;
input 				 [31:0] pc_dx;
input 				 [15:0] imm;
input 		 		  [4:0] rd_addr_dx;
input 				 [31:0] mem_data_dx;
input				 [31:0] mem_data_fp_dx;
output reg 					mem_to_reg_xm;
output reg 					reg_write_xm;
output reg 					mem_read_xm;
output reg 					mem_write_xm;
output reg 					branch_xm;
output reg 					fp_operation_xm;
output reg 			 [31:0] alu_out_xm;
output reg 			 [31:0] branch_addr_xm;
output reg 			 [31:0] alu_out_fp_xm;
output reg 			  [4:0] rd_addr_xm;
output reg 			 [31:0] mem_data_xm;
output reg 			 [31:0] mem_data_fp_xm;

wire 				 [31:0] fp_add_ans;
wire 				 [31:0] fp_mul_ans;


//set pipeline register
always @(posedge clk or negedge rstn)
begin
	if(!rstn) begin 
		mem_to_reg_xm		<= 1'b0;
		reg_write_xm		<= 1'b0;
		mem_read_xm 		<= 1'b0;
		mem_write_xm		<= 1'b0;
		rd_addr_xm 	   		<= 5'b0;
		mem_data_xm 	   	<= 32'b0;
		branch_xm			<= 1'b0;
		branch_addr_xm		<= 32'b0;
		fp_operation_xm 	<= 1'b0;
	end else begin
		mem_to_reg_xm		<= mem_to_reg_dx;
		reg_write_xm		<= reg_write_dx;
		mem_read_xm 		<= mem_read_dx;
		mem_write_xm		<= mem_write_dx;
		rd_addr_xm 	   		<= rd_addr_dx;
		mem_data_xm 	   	<= mem_data_dx;
		mem_data_fp_xm		<= mem_data_fp_dx;
	    branch_xm			<= ((alu_ctrl==5) && (alu_src1 == alu_src2) && (branch_dx))? 1'b1 : ((alu_ctrl==6) && (alu_src1 != alu_src2) && (branch_dx)) ? 1'b1 : 1'b0;
		branch_addr_xm		<= pc_dx + {{15{imm[15]}}, imm, 2'b0};
		fp_operation_xm 	<= fp_operation_dx;
	end
end

always @(posedge clk or negedge rstn)
begin
   if(!rstn) begin
   		alu_out_xm <= 32'b0;
   end 
   else begin
   		case(alu_ctrl)
		  	4'd0:
				alu_out_xm <= alu_src1 & alu_src2;
			4'd1:
				alu_out_xm <= alu_src1 | alu_src2;
			4'd2:
				alu_out_xm <= alu_src1 + alu_src2;
			4'd6:
				alu_out_xm <= alu_src1 - alu_src2;
			4'd7:
				alu_out_xm <= alu_src1 < alu_src2 ? 1 : 0;
			default:
				alu_out_xm <= alu_out_xm;
		endcase
		
   end
end

always @(posedge clk or negedge rstn)
begin
   if(!rstn) begin
   		alu_out_fp_xm <= 32'b0;
   end 
   else begin
   		case(alu_ctrl)
		  	4'd8: //lwc1, swc1
		     	alu_out_fp_xm <= alu_src1_fp + alu_src2_fp;
			4'd9: //add.s
			 	alu_out_fp_xm <= fp_add_ans;
			4'd10: //mul.s
			 	alu_out_fp_xm <= fp_mul_ans;
            default:
                alu_out_fp_xm <= alu_out_fp_xm;
		endcase
   end
end


fp_add fp_add(
   .s_axis_a_tvalid(1'b1),                  
   .s_axis_a_tdata(alu_src1_fp),            
   .s_axis_b_tvalid(1'b1),                  
   .s_axis_b_tdata(alu_src2_fp),            
   .m_axis_result_tvalid(),                 
   .m_axis_result_tdata(fp_add_ans)         
);
fp_mul fp_mul(
	.s_axis_a_tvalid(1'b1),         		 
   .s_axis_a_tdata(alu_src1_fp),              
   .s_axis_b_tvalid(1'b1),            		
   .s_axis_b_tdata(alu_src2_fp),               
   .m_axis_result_tvalid(),                    
   .m_axis_result_tdata(fp_mul_ans)            
);
endmodule
	