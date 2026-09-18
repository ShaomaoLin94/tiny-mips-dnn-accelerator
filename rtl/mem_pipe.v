module mem_pipe(
    input clk, rstn, valid_xm, mem_write_xm,
    input [31:0] address_xm, store_data_xm,
    input [10:0] ahb_dm_addr,
    input [31:0] ahb_dm_din,
    input ahb_dm_wen,
    output [31:0] ahb_dm_dout, load_data_mw
);
    wire [10:0] addr = rstn ? address_xm[12:2] : ahb_dm_addr;
    wire [31:0] data = rstn ? store_data_xm : ahb_dm_din;
    wire we = rstn ? (valid_xm && mem_write_xm) : ahb_dm_wen;

    // 讀取結果會在 MEM/WB 控制訊號更新後一起出現。
    sram data_mem(.addra(addr), .clka(clk), .dina(data),
        .douta(load_data_mw), .ena(1'b1), .wea(we), .addr_out());
    assign ahb_dm_dout = load_data_mw;
endmodule
