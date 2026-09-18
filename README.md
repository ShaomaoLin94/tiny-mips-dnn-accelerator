# 5-stage MIPS-Based MNIST Accelerator

## 專案簡介

本專案以計算機組織課程提供的 5-stage MIPS processor 為基礎，針對 Fully Connected Deep Neural Network（FC-DNN）中大量的浮點乘加運算進行加速。處理器維持 IF、ID、EX、MEM 與 WB 五階段 pipeline，並加入自訂 MAC 指令、data forwarding 及 pipeline interlock，以減少資料相依造成的 NOP 與等待週期。

專案使用課程提供的 784-64-10 MNIST 模型進行 RTL simulation。MIPS processor 負責各層 neuron 的 inner product 運算，testbench 則依照原始辨識流程處理 bias、ReLU 與輸出分類，最後取得手寫數字的預測結果。

## 架構優化

### Custom MAC Instruction

新增 `mac.s fd, fs, ft` 浮點乘加指令，運算內容如下：

```text
fd = fd + fs * ft
```

原本的 neuron 計算需要分別執行 `mul.s` 與 `add.s`，MAC 指令將兩個操作整合為一條指令，可減少迴圈中的指令數量。

### Data Forwarding

Forwarding unit 會檢查 EX/MEM 與 MEM/WB 階段的目的暫存器。當後續指令需要前一筆運算結果時，資料可直接送回 EX stage，不必等待暫存器完成 write back。整數與浮點暫存器會分開比對，避免錯誤轉送。

### Pipeline Interlock

Load 指令的資料需到 MEM stage 才能取得，因此緊接在後的相依指令仍可能發生 load-use hazard。Hazard unit 偵測到此情況時會暫停 IF/ID 一個週期，並在 EX stage 插入 bubble，確保後續指令取得正確資料。

## MNIST 推論流程

模型包含一層 64-neuron hidden layer 與一層 10-neuron output layer。每顆 neuron 的 input 與 weight 會寫入 Data Memory，再由 MIPS processor 執行浮點內積。Hidden layer 的結果經過 bias 與 ReLU 後送入 output layer，最後比較 10 個輸出值並選出預測類別。

`mnist_tb.v` 使用課程提供的模型參數與第 0 張 MNIST 測試影像進行完整推論，該影像的正確標籤為 7。

## 專案結構

- `baseline/`：課程原始 MIPS RTL。
- `rtl/`：加入 MAC、forwarding 與 interlock 的 RTL。
- `programs/`：MIPS machine code 與指令列表。
- `sim/`：RTL testbench 與 MNIST 測試資料。
- `results/`：Simulation 輸出紀錄。
- `Makefile`：編譯與執行指令。

## 開發環境

- Icarus Verilog
- GTKWave
- GNU Make

Ubuntu 或 WSL 可使用下列指令安裝：

```bash
sudo apt update
sudo apt install iverilog gtkwave make
```

## Simulation

執行 hazard/forwarding 與浮點乘加測試：

```bash
make test
```

比較 baseline 與 optimized design 的乘加週期：

```bash
make compare
```

執行單張 MNIST 推論：

```bash
make mnist
```

產生並開啟 MAC 測試波形：

```bash
make wave
gtkwave build/mac.vcd
```

Simulation log 會儲存在 `results/`。其中 `baseline.log` 與 `mac.log` 記錄乘加測試的 cycle count，`mnist.log` 記錄 MNIST 預測結果與推論週期。

## 測試項目

- `hazard_tb.v`：驗證 load-use stall，以及 EX/MEM、MEM/WB forwarding。
- `mac_tb.v`：執行 1023 次浮點乘加，預期結果為 `1023.0`。
- `mnist_tb.v`：執行 784-64-10 FC-DNN 推論，檢查輸出類別是否為 7。
