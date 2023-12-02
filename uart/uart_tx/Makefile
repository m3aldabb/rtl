run:
	iverilog -g2012 -o uart_tx.vvp uart_tx.sv uart_tx_tb.sv
	vvp uart_tx.vvp
	rm uart_tx.vvp

waves:
	gtkwave.exe waves.vcd