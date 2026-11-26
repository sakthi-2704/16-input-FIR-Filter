# Baseline clock constraint (100 MHz). Improvement run: tighten this, e.g. 5.000 (200 MHz).
create_clock -period 10.000 -name clk [get_ports clk]
