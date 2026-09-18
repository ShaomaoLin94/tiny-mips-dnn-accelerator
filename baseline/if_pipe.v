module if_pipe(
	clk,
	rstn,
	jump_dx,
	branch_xm,
	jump_addr,
	branch_addr_xm,

	fetch_pc,
	fetch_instr,
	
	ahb_im_addr,
	ahb_im_din,
	ahb_im_wen,
	ahb_im_dout
);
input			  		   clk;
input			  		   rstn;
input			  		   jump_dx;
input			  		   branch_xm;
input 				[31:0] jump_addr;
input 				[31:0] branch_addr_xm;
output reg 			[31:0] fetch_pc;
output reg 			[31:0] fetch_instr;

input 				[10:0] ahb_im_addr;
input 				[31:0] ahb_im_din;
input 					   ahb_im_wen;
output 				[31:0] ahb_im_dout;
wire 				[31:0] instr_mem_dout;
wire 				[10:0] instr_mem_addr;
wire 				[31:0] instr_mem_din;
wire 					   instr_mem_we;


assign instr_mem_addr = rstn ? {2'b00, fetch_pc[10:2]} : ahb_im_addr;
assign instr_mem_din = rstn ? 32'b0 : ahb_im_din;
assign instr_mem_we = rstn ? 1'b0 : ahb_im_wen;

assign ahb_im_dout = instr_mem_dout;


//output instr_mem
always @(*)
begin
	if(!rstn)
		fetch_instr <= 32'd0;
	else
		fetch_instr <= instr_mem_dout;
end

// output program counter
always @(posedge clk or negedge rstn)
begin
	if(!rstn)
		fetch_pc <= 32'd0;
	else
		fetch_pc <= (branch_xm) ? branch_addr_xm : ((jump_dx) ? jump_addr : (fetch_pc + 4)) ;
end

sram instr_mem(
    .addra				(instr_mem_addr		),
    .clka				(clk			),
    .dina				(instr_mem_din		),
    .douta				(instr_mem_dout		),
    .ena				(1'b1			),
    .wea				(instr_mem_we		)
);


endmodule
