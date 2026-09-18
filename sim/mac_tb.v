`timescale 1ns/1ps

module mac_tb;
    reg clk;
    reg rstn;
    reg [10:0] im_addr, dm_addr;
    reg [31:0] im_din, dm_din;
    reg im_we, dm_we;
    wire [31:0] im_dout, dm_dout, rf_data;

    reg [31:0] program [0:2047];
    integer i;
    integer cycles;
    integer stalls;

    cpu_top cpu(
        .clk(clk), .rstn(rstn),
        .ahb_rf_addr(5'd6), .ahb_rf_data(rf_data),
        .ahb_im_addr(im_addr), .ahb_im_din(im_din),
        .ahb_im_wen(im_we), .ahb_im_dout(im_dout),
        .ahb_dm_addr(dm_addr), .ahb_dm_din(dm_din),
        .ahb_dm_wen(dm_we), .ahb_dm_dout(dm_dout)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rstn = 0;
        im_we = 0;
        dm_we = 0;
        cycles = 0;
        stalls = 0;

        // 先把沒有使用的 IM 填成 NOP，避免讀到 X。
        for (i = 0; i < 2048; i = i + 1)
            program[i] = 32'h00000020;

`ifdef BASELINE
        $readmemh("baseline/im.txt", program, 0, 39);
`else
        $readmemh("programs/im.txt", program, 0, 49);
`endif

        // CPU 保持 reset，利用原本的 host port 載入 IM 和 DM。
        // DM[0] 放結束位址，DM[1:2046] 放 1023 組 1.0。
        repeat (2) @(negedge clk);
        for (i = 0; i < 2048; i = i + 1) begin
            im_addr = i;
            im_din = program[i];
            im_we = 1;

            dm_addr = i;
            if (i == 0)
                dm_din = 32'd8184;
            else if (i <= 2046)
                dm_din = 32'h3f800000;
            else
                dm_din = 0;
            dm_we = 1;
            @(negedge clk);
        end

        im_we = 0;
        dm_we = 0;
        @(negedge clk);
        rstn = 1;

        // r6=1234 是程式的完成旗標，只計算 CPU 執行 cycles。
        while (cpu.ID.rf.REG_I[6] !== 32'd1234 && cycles < 30000) begin
            @(negedge clk);
            cycles = cycles + 1;
`ifndef BASELINE
            if (cpu.stall)
                stalls = stalls + 1;
`endif
        end

        if (cycles == 30000)
            $fatal(1, "simulation timeout");
        if (cpu.MEM.data_mem.mem[2047] !== 32'h447fc000)
            $fatal(1, "wrong answer: %h", cpu.MEM.data_mem.mem[2047]);

`ifdef BASELINE
        $display("PASS baseline  cycles=%0d output=%h",
                 cycles, cpu.MEM.data_mem.mem[2047]);
`else
        $display("PASS optimized cycles=%0d stalls=%0d output=%h",
                 cycles, stalls, cpu.MEM.data_mem.mem[2047]);
`endif
        $finish;
    end

`ifdef WAVE
    initial begin
        $dumpfile("build/mac.vcd");
        $dumpvars(0, mac_tb);
    end
`endif
endmodule
