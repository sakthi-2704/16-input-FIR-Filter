# PYNQ-Z2 board constraints for fir_top.
# Pin H16 / 125 MHz is the PYNQ-Z2 system clock - cross-check it against the
# board XDC you used in Lab 4 before building.
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports sysclk]
create_clock -period 8.000 -name sysclk [get_ports sysclk]
