run:
	iverilog -g2012 -o uart_rx.vvp uart_rx.sv uart_rx_tb.sv
	vvp uart_rx.vvp
	rm uart_rx.vvp

waves:
	gtkwave.exe waves.vcd