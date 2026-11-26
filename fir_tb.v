// -----------------------------------------------------------------------------
// fir_tb.v -- self-checking testbench for fir_filter
//
// The reference is a direct convolution done on the stored input history, so it
// does not depend on the DUT's internal structure.  y[n] must appear exactly
// LATENCY = 2 cycles after x[n] is applied.  Change LATENCY when you pipeline.
// Stimulus: impulse, step, low-freq sine, high-freq sine, random.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module fir_tb;
    parameter N = 16, DW = 16, CW = 16;
    parameter LATENCY = 2;                 // <-- update for pipelined version
    parameter LEN = 1100;

    reg clk = 0;
    reg rst = 1;
    reg  signed [DW-1:0] x_in = 0;
    wire signed [DW-1:0] y_out;

    fir_filter #(.N(N), .DW(DW), .CW(CW)) dut (.clk(clk), .rst(rst), .x_in(x_in), .y_out(y_out));

    always #5 clk = ~clk;                  // 100 MHz in simulation

    `include "fir_coeffs.vh"

    integer xs  [0:LEN-1];                 // input history
    integer exp_y [0:LEN-1];               // expected output
    integer n, k, errors, checks;
    integer acc, sc;
    integer seed;
    real    pi;

    task build_stimulus;
        integer j;
        begin
            pi = 3.14159265358979;
            seed = 1;
            for (j = 0; j < LEN; j = j + 1) begin
                if      (j < 100) xs[j] = (j == 10) ? 20000 : 0;                    // impulse
                else if (j < 250) xs[j] = 16000;                                    // step
                else if (j < 500) xs[j] = $rtoi(12000.0 * $sin(2.0*pi*(j-250)/64.0));  // low freq (passes)
                else if (j < 750) xs[j] = $rtoi(12000.0 * $sin(2.0*pi*(j-500)*0.40));   // high freq (attenuated)
                else if (j < 1000) xs[j] = ($random(seed) % 20000);                 // random
                else xs[j] = 32767;                                                 // large step -> saturation check
            end
        end
    endtask

    task build_expected;
        integer j, t;
        reg signed [CW-1:0] hh;
        begin
            for (j = 0; j < LEN; j = j + 1) begin
                acc = 0;
                for (t = 0; t < N; t = t + 1) begin
                    hh = COEFFS[t*CW +: CW];
                    if (j - t >= 0) acc = acc + xs[j-t] * hh;
                end
                sc = acc >>> (CW-1);
                if (sc >  32767) sc =  32767;
                if (sc < -32768) sc = -32768;
                exp_y[j] = sc;
            end
        end
    endtask

    initial begin
        $dumpfile("fir_tb.vcd");
        $dumpvars(0, fir_tb);
        build_stimulus;
        build_expected;
        errors = 0; checks = 0;

        repeat (4) @(negedge clk);
        rst = 0;

        // iteration n: check y[n-LATENCY], then apply x[n]
        for (n = 0; n < LEN + LATENCY; n = n + 1) begin
            @(negedge clk);
            if (n >= LATENCY) begin
                checks = checks + 1;
                if (y_out !== exp_y[n-LATENCY]) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("MISMATCH n=%0d: got %0d expected %0d", n-LATENCY, y_out, exp_y[n-LATENCY]);
                end
            end
            x_in = (n < LEN) ? xs[n] : 0;
        end

        $display("--------------------------------------------");
        if (errors == 0) $display("PASS: %0d samples checked, 0 mismatches", checks);
        else             $display("FAIL: %0d mismatches out of %0d samples", errors, checks);
        $display("--------------------------------------------");
        $finish;
    end
endmodule
