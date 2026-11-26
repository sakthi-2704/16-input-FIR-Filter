# Run in the Vivado Tcl console (project open, part xc7z020clg400-1).
# Creates the VIO and ILA cores that fir_top.v instantiates.
create_ip -name vio -vendor xilinx.com -library ip -module_name vio_0
set_property -dict [list \
    CONFIG.C_NUM_PROBE_IN {1} \
    CONFIG.C_NUM_PROBE_OUT {3} \
    CONFIG.C_PROBE_IN0_WIDTH {16} \
    CONFIG.C_PROBE_OUT0_WIDTH {2} \
    CONFIG.C_PROBE_OUT1_WIDTH {16} \
    CONFIG.C_PROBE_OUT2_WIDTH {1} \
    CONFIG.C_PROBE_OUT0_INIT_VAL {0x3} \
    CONFIG.C_PROBE_OUT1_INIT_VAL {0x1F40} \
    CONFIG.C_PROBE_OUT2_INIT_VAL {0x0} \
] [get_ips vio_0]

create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0
set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {3} \
    CONFIG.C_PROBE0_WIDTH {16} \
    CONFIG.C_PROBE1_WIDTH {16} \
    CONFIG.C_PROBE2_WIDTH {2} \
    CONFIG.C_DATA_DEPTH {4096} \
] [get_ips ila_0]

generate_target all [get_ips vio_0 ila_0]
