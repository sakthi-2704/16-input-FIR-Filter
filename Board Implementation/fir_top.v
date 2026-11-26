// -----------------------------------------------------------------------------
// fir_top.v -- PYNQ-Z2 board top for the FIR demo (use with fir_filter_v2.v)
//
//   VIO  : mode[1:0], amp[15:0], rst  (you set these in Hardware Manager)
//   stim_gen -> fir_filter -> y_out
//   ILA  : x_in, y_out, mode  (captures at the full 125 MHz clock)
//   VIO probe_in shows the live y_out value.
// vio_0 and ila_0 are Vivado IP cores: create them with create_ips.tcl
// (or the IP Catalog, settings in the README) before synthesis.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module fir_top (
    input wire sysclk            // 125 MHz board clock
);
    wire [1:0]          mode;
    wire [15:0]         amp;
    wire                rst_vio;
    wire signed [15:0]  x_in;
    wire signed [15:0]  y_out;

    vio_0 u_vio (
        .clk        (sysclk),
        .probe_in0  (y_out),
        .probe_out0 (mode),
        .probe_out1 (amp),
        .probe_out2 (rst_vio)
    );

    stim_gen u_stim (
        .clk (sysclk), .rst (rst_vio), .mode (mode), .amp (amp), .x (x_in)
    );

    fir_filter u_fir (
        .clk (sysclk), .rst (rst_vio), .x_in (x_in), .y_out (y_out)
    );

    ila_0 u_ila (
        .clk    (sysclk),
        .probe0 (x_in),
        .probe1 (y_out),
        .probe2 (mode)
    );
endmodule
