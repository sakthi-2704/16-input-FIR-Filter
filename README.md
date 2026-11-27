# # 16-Tap FIR Filter: Vivado Flow Study on PYNQ-Z2

Course project for EE6043 (Digital IC Design). A 16-tap low-pass FIR filter is taken through the
full Vivado flow (RTL, simulation, synthesis, implementation, bitstream) in two versions:
a direct-form baseline (v1) and a transposed-form improvement (v2), with the results compared
at the same clock constraint.

## Results at a glance

Vivado 2022.1, part xc7z020clg400-1, 10 ns clock constraint for both versions.

| Metric | v1 (direct form) | v2 (transposed) |
|---|---|---|
| WNS | -22.753 ns (fails) | +5.82 ns (passes) |
| Critical path | about 32.75 ns | about 4.18 ns |
| Estimated Fmax | about 30.5 MHz | about 239 MHz |
| LUTs / FFs / DSP48 | 37 / 240 / 16 | 29 / 16 / 16 |
| Total power | 0.138 W | 0.140 W (about the same) |
| Latency | 2 cycles | 2 cycles |

Fmax is estimated as 1 / (10 ns - WNS), so it is approximate. Power uses Vivado's default switching
activity, so the small difference is within estimation noise.

## The design

- 16-bit signed input and output, 16-bit Q1.15 coefficients, 36-bit accumulator, shift right by 15 with saturation.
- Coefficients: `scipy.signal.firwin`, Hamming window, 16 taps, cutoff 0.25 x Nyquist (DC gain 1.0).
- **v1:** input delay line followed by one combinational multiply-accumulate chain.
- **v2:** the input is broadcast to all multipliers and each tap registers its own partial sum
  (`s[k] <= x*h[k] + s[k+1]`). Same ports, coefficients and latency, so the same testbench applies.

## Files

| File | Purpose |
|---|---|
| `gen_coeffs.py` | Designs and quantises the filter; writes `fir_coeffs.vh` |
| `fir_coeffs.vh` | Generated coefficients (set as Verilog Header in Vivado) |
| `fir_filter.v` | v1 baseline RTL |
| `fir_filter_v2.v` | v2 transposed-form RTL (same module name as v1; use one per project) |
| `fir_tb.v` | Self-checking testbench (simulation source) |
| `fir_timing.xdc` | 10 ns clock constraint used for the comparison |
| `stim_gen.v`, `fir_top.v`, `fir_board.xdc`, `create_ips.tcl` | PYNQ-Z2 demo: on-chip stimulus, VIO/ILA top, board constraints, IP creation script |

## Running it

**Simulation (Vivado):** add the RTL as design sources (`fir_coeffs.vh` as Verilog Header) and `fir_tb.v` as a
simulation source, then run behavioural simulation. The console prints `PASS: 1100 samples checked, 0 mismatches`.

**Simulation (Icarus Verilog), from the folder containing `fir_coeffs.vh`:**

    iverilog -g2005 -o sim fir_filter.v fir_tb.v && vvp sim

Use `fir_filter_v2.v` in place of `fir_filter.v` for v2.

**Implementation:** create a project for xc7z020clg400-1, add the RTL and `fir_timing.xdc`, then run synthesis
and implementation. Record WNS, utilisation and power from the reports.

**Board demo:** create the cores with `source create_ips.tcl`, use `fir_top` as the top with `fir_board.xdc`,
generate the bitstream, and program the PYNQ-Z2. The VIO selects one of four test signals (constant, slow square,
fast alternating, slow plus fast) and the ILA shows input and output.

## Notes

- The testbench compares the DUT against a direct convolution of the stored inputs. It shares the coefficient file
  with the DUT, so the coefficients are checked separately by `gen_coeffs.py`.
- The RTL was written with AI assistance. The circuit and improvement choices, the Vivado runs and the results are
  the author's own work.
- Coefficients come from `scipy.signal.firwin`.
