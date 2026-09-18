# 5-stage MIPS-Based MNIST Accelerator

## 專案簡介

本專案以計算機組織課程提供的 5-stage MIPS processor 為基礎，針對 Fully Connected Deep Neural Network（FC-DNN）中大量的浮點乘加運算進行優化。處理器維持 IF、ID、EX、MEM 與 WB 五階段 pipeline，並加入自訂 MAC 指令、data forwarding 及 pipeline interlock，以減少資料相依造成的 NOP 與等待週期。

在 1023 次浮點乘加測試中，執行週期由 baseline 的 **25,595 cycles** 降至優化後的 **10,249 cycles**，減少 **59.96%**，以 cycle count 計算的 speedup 為 **2.50×**。另以課程提供的 784-64-10 MNIST 模型執行單張影像推論，預測結果為 **7**，與正確標籤一致。

## 架構優化

### Custom MAC Instruction

新增 `mac.s fd, fs, ft` 浮點乘加指令，執行 `fd = fd + fs * ft`。原本的 neuron 計算需要分別執行 `mul.s` 與 `add.s`，整合後可減少內積迴圈中的指令數量。MAC 沿用浮點乘法與加法模組依序計算，並非單次捨入的 fused multiply-add。

### Data Forwarding

Forwarding unit 會檢查 EX/MEM 與 MEM/WB 階段的目的暫存器，將可用的運算結果直接送往 EX stage，減少等待 write back 的需求。兩個階段同時符合轉送條件時，優先選擇較新的 EX/MEM 結果；整數與浮點暫存器分開比對，避免錯誤轉送。

### Pipeline Interlock

Load 指令的資料需到 MEM stage 才能取得。當後續指令立即使用該資料時，hazard unit 會暫停 IF/ID 一個週期，並在 EX stage 插入 bubble。搭配 forwarding 後，內積程式可移除原本用於處理資料相依的大量 NOP。

## 實驗結果

### 浮點乘加效能比較

測試工作負載為 1023 組 `1.0 × 1.0` 的累加。Baseline 執行課程原始指令程式，優化版執行移除相依性 NOP 並使用 `mac.s` 的程式。

| 項目 | Baseline | Optimized |
| --- | ---: | ---: |
| 執行週期 | 25,595 | 10,249 |
| 計算結果 | 1023.0 | 1023.0 |
| 結果的 IEEE754 編碼 | `447fc000` | `447fc000` |
| 測試結果 | PASS | PASS |

執行週期減少比例為 `(25,595 − 10,249) / 25,595 = 59.96%`，cycle-count speedup 為 `25,595 / 10,249 ≈ 2.50×`。此比較呈現 MAC、forwarding、interlock 與指令程式調整的整體效果，不代表單一優化的個別貢獻。

Cycles 從 CPU 解除 reset 計算至完成旗標出現，不包含 testbench 載入指令及資料的時間。上述 speedup 是執行週期的比較，未納入合成後最高時脈與 critical path 的差異。

<!-- 圖片位置：將 make compare 的 terminal 截圖存為 docs/images/mac-comparison.png。 -->
![Baseline 與優化版乘加測試結果](docs/images/mac-comparison.png)

圖 1：Baseline 與優化版皆得到相同的浮點累加結果。優化版使用較少的執行週期完成相同工作負載。

### Load-use Hazard 驗證

`hazard_tb.v` 的 load-use stall 與 forwarding 測試結果為 PASS。乘加測試中的優化版共記錄 1023 次 stall，對應內積迴圈中 load 後立即使用資料的情況；開啟波形輸出後，cycle count 與計算結果均與一般執行相同。

<!-- 圖片位置：將 GTKWave 截圖存為 docs/images/load-use-stall.png。
保留 clk、rstn、fetch_pc、fetch_instr、stall、valid_dx，聚焦 C4A20000 後接 7001113E 的片段，包含前後數個 clock。
-->
![Load-use hazard 的 pipeline 波形](docs/images/load-use-stall.png)

圖 2：`lwc1` 後接使用相同浮點暫存器的 `mac.s` 時，`stall` 拉高。在下一個 clock 上升緣，`fetch_pc` 保持不變，`valid_dx` 降為 0，表示 EX stage 插入一個 bubble。資料可用後，pipeline 恢復執行。

### MNIST 推論結果

MNIST 模型具有 784 個輸入、一層 64-neuron hidden layer 與一層 10-neuron output layer。Testbench 將各 neuron 的 input 與 weight 寫入 Data Memory，由 MIPS processor 執行 inner product；bias、ReLU 與最後的最大值比較則由 testbench 處理。Hidden layer 的計算結果會作為 output layer 的輸入。

本次使用課程提供的第 0 張測試影像，模擬輸出如下：

```text
PASS MNIST image=00000 prediction=7 cpu_cycles=509566
```

預測類別 **7** 與正確標籤一致，兩層網路共 74 顆 neuron 的內積運算累計 **509,566 CPU cycles**。此數值不包含 testbench 的資料載入、bias、ReLU 與分類處理時間。本測試驗證單張影像的辨識流程，不作為完整 MNIST 測試集準確率或 MNIST 整體加速比的量測。

<!-- 圖片位置：將 make mnist 的 terminal 結果截圖存為 docs/images/mnist-result.png。 -->
![MNIST 單張影像辨識結果](<img width="1293" height="133" alt="螢幕擷取畫面 2026-09-18 103251" src="https://github.com/user-attachments/assets/467cd4fc-9c8a-4c6f-ba48-2c26d0036b6f" />)

圖 3：使用課程模型執行第 0 張 MNIST 影像推論，預測結果為 7，與標籤一致。`cpu_cycles` 記錄各 neuron 內積運算的 CPU 執行週期總和。

實驗紀錄分別位於 `results/baseline.log`、`results/mac.log`、`results/hazard.log`、`results/mac_wave.log` 與 `results/mnist.log`。

## 專案結構

- `baseline/`：課程原始 MIPS RTL。
- `rtl/`：加入 MAC、forwarding 與 interlock 的 RTL。
- `programs/`：MIPS machine code 與指令列表。
- `sim/`：RTL testbench 與 MNIST 測試資料。
- `results/`：Simulation 輸出紀錄。
- `docs/images/`：實驗結果與波形截圖。
- `Makefile`：編譯與執行指令。

## 開發環境與執行方式

使用 Icarus Verilog 進行模擬，搭配 GNU Make 執行測試，並以 GTKWave 查看波形。Ubuntu 或 WSL 可使用下列指令安裝：

```bash
sudo apt update
sudo apt install iverilog gtkwave make
```

以下指令均在包含 `Makefile` 的專案根目錄執行：

```bash
# 執行 hazard/forwarding 與浮點乘加測試
make test

# 比較 baseline 與 optimized design 的乘加週期
make compare

# 執行單張 MNIST 推論
make mnist

# 產生並開啟 MAC 測試波形
make wave
gtkwave build/mac.vcd

# 產生並開啟 MNIST 推論波形
make mnist-wave
gtkwave build/mnist.vcd
```

模擬紀錄儲存於 `results/`，波形儲存於 `build/`。`hazard_tb.v` 檢查 load-use stall 與 EX/MEM、MEM/WB forwarding；`mac_tb.v` 檢查 1023 次乘加的結果；`mnist_tb.v` 檢查單張影像的預測類別是否為 7。
