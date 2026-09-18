module if_pipe(
    input clk, rstn, stall, redirect,
    input [31:0] redirect_pc,
    output reg [31:0] fetch_pc, pc4_fd,
    output [31:0] fetch_instr,
    output reg valid_fd,
    input [10:0] ahb_im_addr,
    input [31:0] ahb_im_din,
    input ahb_im_wen,
    output [31:0] ahb_im_dout
);
    wire [10:0] addr = rstn ? fetch_pc[12:2] : ahb_im_addr;
    wire [31:0] data;
    assign fetch_instr = data;
    assign ahb_im_dout = data;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            fetch_pc <= 0;
            pc4_fd <= 0;
            valid_fd <= 0;
        end else if (redirect) begin
            fetch_pc <= redirect_pc;
            valid_fd <= 0;
        end else if (!stall) begin
            pc4_fd <= fetch_pc + 4;
            fetch_pc <= fetch_pc + 4;
            valid_fd <= 1;
        end
    end

    // SRAM 的讀位址暫存器就是 IF/ID 的一部分，stall 時也要一起停。
    sram instr_mem(
        .addra(addr), .clka(clk), .dina(ahb_im_din), .douta(data),
        .ena(!rstn || (!stall && !redirect)),
        .wea(!rstn && ahb_im_wen), .addr_out()
    );
endmodule
