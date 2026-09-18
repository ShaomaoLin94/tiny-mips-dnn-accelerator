IVERILOG ?= iverilog
VVP ?= vvp

OPT_RTL := $(wildcard rtl/*.v)
BASE_RTL := $(wildcard baseline/*.v)

.PHONY: test hazard mac mnist baseline compare wave clean

# 預設只跑兩個較快、也最重要的測試。
test: hazard mac

hazard:
	@mkdir -p build results
	$(IVERILOG) -g2005 -Wall -s hazard_tb -o build/hazard.vvp \
		rtl/hazard_unit.v rtl/forwarding_unit.v sim/hazard_tb.v
	$(VVP) build/hazard.vvp > results/hazard.log
	@cat results/hazard.log

mac:
	@mkdir -p build results
	$(IVERILOG) -g2005 -Wall -I rtl -s mac_tb -o build/mac.vvp \
		$(OPT_RTL) sim/mac_tb.v
	$(VVP) build/mac.vvp > results/mac.log
	@cat results/mac.log

# 完整跑一張課程提供的 MNIST 圖片，執行時間會比 make test 久。
mnist:
	@mkdir -p build results
	$(IVERILOG) -g2005 -Wall -I rtl -s mnist_tb -o build/mnist.vvp \
		$(OPT_RTL) sim/mnist_tb.v
	$(VVP) build/mnist.vvp > results/mnist.log
	@cat results/mnist.log

baseline:
	@mkdir -p build results
	$(IVERILOG) -g2005 -Wall -DBASELINE -I baseline -s mac_tb \
		-o build/baseline.vvp $(BASE_RTL) sim/mac_tb.v
	$(VVP) build/baseline.vvp > results/baseline.log
	@cat results/baseline.log

compare: baseline mac
	@echo "請比較 results/baseline.log 與 results/mac.log 的 cycles。"

wave:
	@mkdir -p build results
	$(IVERILOG) -g2005 -Wall -DWAVE -I rtl -s mac_tb \
		-o build/mac_wave.vvp $(OPT_RTL) sim/mac_tb.v
	$(VVP) build/mac_wave.vvp > results/mac_wave.log
	@cat results/mac_wave.log
	@echo "波形位於 build/mac.vcd"

clean:
	rm -rf build
	rm -f results/*.log
