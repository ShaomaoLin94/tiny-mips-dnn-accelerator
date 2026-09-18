module rf(
    clk,
    rstn,
    rs_addr,
    rs_data,
    rt_addr,
    rt_data,
    rd_addr,
    rd_data,
    reg_write_mw,
    mem_to_reg_mw,
    mem_data_to_reg,
    alu_out_mw,
    fp_operation_mw,
    ahb_rf_addr,
	ahb_rf_data
);
input			  		   clk;
input			  		   rstn;
input                [4:0] rs_addr;
input                [4:0] rt_addr;
input                [4:0] rd_addr;
output reg          [31:0] rs_data;
output reg          [31:0] rt_data;
output reg          [31:0] rd_data;
input                      reg_write_mw;
input                      mem_to_reg_mw;
input               [31:0] mem_data_to_reg;
input               [31:0] alu_out_mw;
input                      fp_operation_mw;
input                [4:0] ahb_rf_addr;
output reg          [31:0] ahb_rf_data;
reg                 [31:0] REG_I [0:31];

reg                  [5:0] i;

//ahb rf probe
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        ahb_rf_data <= 32'd0;
    end
    else begin
        ahb_rf_data <= REG_I[ahb_rf_addr];
    end
end

//write back
always @(posedge clk or negedge rstn)
if(!rstn) begin
    for (i=0; i<32; i=i+1) begin
        REG_I[i] <= 32'b0;
    end
end
else if(reg_write_mw && !fp_operation_mw && rd_addr != 5'd0) begin
    REG_I[rd_addr] <= (mem_to_reg_mw) ? mem_data_to_reg : alu_out_mw;
end
else begin
    REG_I[rd_addr] <= REG_I[rd_addr];
end
    

//read data to rs
always @* begin
    rs_data = REG_I[rs_addr];
end
//read data to rt
always @* begin
    rt_data = REG_I[rt_addr];
end
endmodule