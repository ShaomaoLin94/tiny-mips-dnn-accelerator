module sram(addra, clka, dina, douta, ena, wea,addr_out);
	
	input clka, ena, wea;
	input [10:0] addra;
	input [31:0] dina;
	output [31:0] douta;
	output [31:0] addr_out;

	reg [31:0] mem[0:2047];
	reg [31:0] addr_reg;
	
	assign douta = mem[addr_reg];
   	assign addr_out = addr_reg;
	
	always @(posedge clka)
	begin
		if(wea) begin
			mem[addra] <= dina;
		end	
		else begin
			mem[addra] <= mem[addra];
		end	
		if(ena)	begin
			addr_reg <= addra;
		end
		else begin
			addr_reg <= addr_reg;
		end
	end

endmodule
