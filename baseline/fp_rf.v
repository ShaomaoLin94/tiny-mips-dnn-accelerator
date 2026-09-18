`timescale 1ns/1ps

module fp_rf(
    clk,
    rstn,
    fp_rs_addr,
    fp_rs_data,
    fp_rt_addr,
    fp_rt_data,
    fp_rd_addr,
    fp_rd_data,
    fp_operation_mw,
    reg_write_mw,
    mem_to_reg_mw,
    mem_data_to_reg_fp,
    alu_out_fp_mw
);
input			  		   clk;
input			  		   rstn;
input                [4:0] fp_rs_addr;
input                [4:0] fp_rt_addr;
input                [4:0] fp_rd_addr;
input                      reg_write_mw;
input                      mem_to_reg_mw;
input                      fp_operation_mw;
input               [31:0] mem_data_to_reg_fp;
input               [31:0] alu_out_fp_mw;
output reg          [31:0] fp_rs_data;
output reg          [31:0] fp_rt_data;
output reg          [31:0] fp_rd_data;
reg                 [31:0] REG_F [0:31];
reg                  [5:0] i;

//write back
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        for (i=0; i<32; i=i+1) begin
            REG_F[i] <= 32'b0;
        end
    end
    else if(reg_write_mw && fp_operation_mw && fp_rd_addr != 5'd0) begin
        REG_F[fp_rd_addr] <= (mem_to_reg_mw) ? mem_data_to_reg_fp : alu_out_fp_mw;
    end
    else begin
        REG_F[fp_rd_addr] <= REG_F[fp_rd_addr];
    end
end

//read data to rs
always @* begin
    fp_rs_data = REG_F[fp_rs_addr];
end

//read data to rt
always @* begin
    fp_rt_data = REG_F[fp_rt_addr];
end
endmodule