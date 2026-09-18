`timescale 1ns/1ps

module mnist_tb;
    reg clk, rstn;
    reg [10:0] im_addr, dm_addr;
    reg [31:0] im_din, dm_din;
    reg im_we, dm_we;
    wire [31:0] im_dout, dm_dout, rf_data;

    reg [31:0] program [0:2047];
    reg [31:0] params [0:50889];
    reg [31:0] image [0:783];
    reg [31:0] hidden [0:63];
    reg [31:0] scores [0:9];
    reg [31:0] add_a, add_b;
    wire [31:0] add_result;
    integer i, neuron, best, total_cycles;

    cpu_top cpu(
        .clk(clk), .rstn(rstn),
        .ahb_rf_addr(5'd6), .ahb_rf_data(rf_data),
        .ahb_im_addr(im_addr), .ahb_im_din(im_din),
        .ahb_im_wen(im_we), .ahb_im_dout(im_dout),
        .ahb_dm_addr(dm_addr), .ahb_dm_din(dm_din),
        .ahb_dm_wen(dm_we), .ahb_dm_dout(dm_dout)
    );

    // Bias 仍照原本 C 程式的方式，在每顆 neuron 算完後加入。
    fp_add bias_adder(
        .s_axis_a_tvalid(1'b1), .s_axis_a_tdata(add_a),
        .s_axis_b_tvalid(1'b1), .s_axis_b_tdata(add_b),
        .m_axis_result_tvalid(), .m_axis_result_tdata(add_result)
    );

    always #5 clk = ~clk;

    function fp_greater;
        input [31:0] left, right;
        begin
            if (left[31] != right[31])
                fp_greater = !left[31];
            else if (!left[31])
                fp_greater = left[30:0] > right[30:0];
            else
                fp_greater = left[30:0] < right[30:0];
        end
    endfunction

    task run_neuron;
        input integer input_count;
        input integer weight_base;
        input integer layer;
        output [31:0] neuron_value;
        integer index, cycles;
        reg [31:0] value;
        begin
            // 每顆 neuron 共用同一段 MIPS 程式，因此換資料前先 reset。
            rstn = 0;
            dm_we = 0;
            repeat (2) @(negedge clk);

            dm_addr = 0;
            dm_din = input_count * 8;
            dm_we = 1;
            @(negedge clk);
            for (index = 0; index < input_count; index = index + 1) begin
                dm_addr = index * 2 + 1;
                dm_din = params[weight_base + index + 1];
                @(negedge clk);
                dm_addr = index * 2 + 2;
                dm_din = (layer == 1) ? image[index] : hidden[index];
                @(negedge clk);
            end
            dm_we = 0;
            im_addr = 2047;
            @(negedge clk);
            rstn = 1;

            cycles = 0;
            while (cpu.ID.rf.REG_I[6] !== 32'd1234 && cycles < 20000) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (cycles == 20000)
                $fatal(1, "neuron simulation timeout");
            total_cycles = total_cycles + cycles;

            value = cpu.MEM.data_mem.mem[input_count * 2 + 1];
            add_a = value;
            add_b = params[weight_base];
            #1;
            neuron_value = add_result;
        end
    endtask

    initial begin
        clk = 0; rstn = 0;
        im_addr = 0; dm_addr = 0;
        im_din = 0; dm_din = 0;
        im_we = 0; dm_we = 0;
        add_a = 0; add_b = 0;
        total_cycles = 0;

        for (i = 0; i < 2048; i = i + 1)
            program[i] = 32'h00000020;
        $readmemh("programs/im.txt", program, 0, 49);
        $readmemh("sim/data/model.hex", params, 0, 50889);
        $readmemh("sim/data/image_00000.hex", image, 0, 783);

        // IM 只需要載入一次，之後各 neuron 只更換 DM 內容。
        repeat (2) @(negedge clk);
        for (i = 0; i < 2048; i = i + 1) begin
            im_addr = i;
            im_din = program[i];
            im_we = 1;
            @(negedge clk);
        end
        im_we = 0;

        // 第一層：784 個輸入、64 顆 neuron，輸出套用 ReLU。
        for (neuron = 0; neuron < 64; neuron = neuron + 1) begin
            run_neuron(784, neuron * 785, 1, hidden[neuron]);
            if (hidden[neuron][31])
                hidden[neuron] = 0;
        end

        // 第二層：64 個輸入、10 顆輸出 neuron。
        for (neuron = 0; neuron < 10; neuron = neuron + 1)
            run_neuron(64, 50240 + neuron * 65, 2, scores[neuron]);

        best = 0;
        for (neuron = 1; neuron < 10; neuron = neuron + 1)
            if (fp_greater(scores[neuron], scores[best]))
                best = neuron;

        if (best != 7)
            $fatal(1, "MNIST image 00000 predicted %0d, expected 7", best);
        $display("PASS MNIST image=00000 prediction=%0d cpu_cycles=%0d",
                 best, total_cycles);
        $finish;
    end
endmodule
