module mem_pipe(
	clk,
	rstn,
	mem_to_reg_xm,
	reg_write_xm,
	mem_read_xm,
	mem_write_xm,
	alu_out_xm,
	alu_out_fp_xm,
	rd_addr_xm,
	mem_data_xm,
	mem_data_fp_xm,
	fp_operation_xm,

	mem_to_reg_mw,
	reg_write_mw,
	alu_out_mw,
	alu_out_fp_mw,
	mem_data_to_reg,
	mem_data_to_reg_fp,
	rd_addr_mw,
	fp_operation_mw,

	ahb_dm_addr,
	ahb_dm_din,
	ahb_dm_wen,
	ahb_dm_dout
);
input			  		   clk;
input			  		   rstn;
input			  		   mem_to_reg_xm;
input			  		   reg_write_xm;
input			  		   mem_read_xm;
input			  		   mem_write_xm;
input			  		   fp_operation_xm;
input 				[31:0] alu_out_xm;
input 				[31:0] alu_out_fp_xm;
input 				 [4:0] rd_addr_xm;
input 				[31:0] mem_data_xm;
input 				[31:0] mem_data_fp_xm;
output reg				   mem_to_reg_mw;
output reg				   reg_write_mw;
output reg				   fp_operation_mw;
output reg 			[31:0] alu_out_mw;
output reg			[31:0] alu_out_fp_mw;
output 				[31:0] mem_data_to_reg;
output 				[31:0] mem_data_to_reg_fp;
output reg 			 [4:0] rd_addr_mw;
input 				[10:0] ahb_dm_addr;
input 				[31:0] ahb_dm_din;
input 					   ahb_dm_wen;
output 				[31:0] ahb_dm_dout;

wire 				[31:0] data_mem_dout;
reg 				[10:0] data_mem_addr;
reg 				[31:0] data_mem_din;
reg 					   data_mem_we;
reg 					   mem_read_mw;
reg 				[31:0] mem_data_to_reg_tmp;
reg 				[31:0] mem_data_to_reg_fp_tmp;
reg 					   ahb_dm_wen_reg;

always @(posedge clk) begin
	ahb_dm_wen_reg <= ahb_dm_wen;
end

assign ahb_dm_dout = ahb_dm_wen_reg ? 32'd0 : data_mem_dout;

always @(*) begin
	if(rstn)begin
		if(!fp_operation_xm) begin		//not fp instruction
			data_mem_addr <= alu_out_xm[12:2];
			data_mem_din  <= mem_data_xm;
		end
		else begin
			data_mem_addr <= alu_out_fp_xm[12:2];
			data_mem_din  <= mem_data_fp_xm;
		end
		
		data_mem_we <= mem_write_xm;
	end
	else begin
		data_mem_addr <= ahb_dm_addr;
		data_mem_din  <= ahb_dm_din;
		data_mem_we   <= ahb_dm_wen;
	end
end

always @(posedge clk or negedge rstn)
	if (!rstn) begin
		mem_to_reg_mw 		<= 1'b0;
		reg_write_mw 		<= 1'b0;
		mem_data_to_reg_tmp				<= 32'b0;
		mem_data_to_reg_fp_tmp			<= 32'b0;
		alu_out_mw			<= 32'b0;
		alu_out_fp_mw		<= 32'b0;
		rd_addr_mw			<= 5'b0;
		
	end
	else begin
		mem_to_reg_mw 				<= mem_to_reg_xm;
		reg_write_mw 				<= reg_write_xm;
		mem_data_to_reg_tmp			<= (mem_read_xm && !fp_operation_xm) ? data_mem_dout : mem_data_to_reg;
		mem_data_to_reg_fp_tmp		<= (mem_read_xm && fp_operation_xm) ? data_mem_dout : mem_data_to_reg_fp;
		alu_out_mw					<= alu_out_xm;
		alu_out_fp_mw				<= alu_out_fp_xm;
		rd_addr_mw 					<= rd_addr_xm;
		fp_operation_mw				<= fp_operation_xm;
		mem_read_mw					<= mem_read_xm;
	end

	assign mem_data_to_reg = mem_read_mw ? data_mem_dout : mem_data_to_reg_tmp;			//check lw, sram delay 1 cycle
	assign mem_data_to_reg_fp = mem_read_mw ? data_mem_dout : mem_data_to_reg_fp_tmp;		//check lwc1, sram delay 1 cycle


sram data_mem(
	.addra(data_mem_addr),
    .clka(clk),
    .dina(data_mem_din),
    .douta(data_mem_dout),
    .ena(1'b1),
    .wea(data_mem_we)
);

endmodule
