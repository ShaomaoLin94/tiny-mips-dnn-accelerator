module fp_mul(
  input s_axis_a_tvalid,
	input [31:0]s_axis_a_tdata,
	input s_axis_b_tvalid,
	input [31:0]s_axis_b_tdata,
	output m_axis_result_tvalid,
	output [31:0]m_axis_result_tdata
);
parameter m=23;
parameter e=8;
parameter p=32;

wire  [p-1:0]Num1,Num2;
wire  [m-1:0]man_out;
wire  [e-1:0]exp_out;
wire  s_out;
wire  [p-1:0]final;

wire [e-1:0]Ea,Eb;
wire [m-1:0]Ma,Mb;
wire [m:0]temp_Ma,temp_Mb;
wire [47:0] temp_prod;
wire msb,Carry1,Carry2,Sa,Sb;
wire [31:0]Sum1,Sum2;

wire [e-1:0]sum,diff,sum1;
wire cout,cout1,cout2;
assign Num1 = s_axis_a_tdata;
assign Num2 = s_axis_b_tdata;
assign m_axis_result_tdata = final;
assign Sa=Num1[p-1];
assign Sb=Num2[p-1];
assign Ea=Num1[p-2:m];
assign Eb=Num2[p-1:m];
assign Ma=Num1[m-1:0];
assign Mb=Num2[m-1:0];

assign temp_Ma[m:0]={1'b1,Ma[m-1:0]};
assign temp_Mb[m:0]={1'b1,Mb[m-1:0]};

xor g1 (s_out,Sa,Sb);

assign temp_prod=temp_Ma * temp_Mb;

assign msb=temp_prod[47];

//rca_n a1 (temp_prod[45:23],temp_prod[22],Carry1,Sum1);
assign Sum1=temp_prod[45:23]+temp_prod[22];
//rca_n a2 (temp_prod[46:24],temp_prod[23],Carry2,Sum2);
assign Sum2=temp_prod[46:24]+temp_prod[23];

assign man_out[m-1:0]=(msb==0) ? Sum1[m-1:0] : Sum2[m-1:0];

//exp_calc i2 (Ea,Eb,exp_out,msb);
assign sum=Ea+Eb;
assign diff=sum-8'b01111111;
assign sum1=diff+1'b1;
assign exp_out[e-1:0]=(msb==0) ? diff[e-1:0] : sum1[e-1:0];

//assign final[p-1:0]={s_out,exp_out[e-1:0],man_out[m-1:0]};

assign final[p-1:0]=(Num1[p-1:0]==0 || Num2[p-1:0]==0) ? 32'b0_00000000_00000000000000000000000 : {s_out,exp_out[e-1:0],man_out[m-1:0]};

endmodule