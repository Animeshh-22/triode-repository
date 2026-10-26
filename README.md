# 4-bit Array Multiplier: RTL to GDSII (SKY130, open-source flow)

## Team

| Name | Roll number |
|---|---|
| Animesh Pandey | 2026203012 |
| Polu Lohith Reddy | 2026203004 |

Technology: SkyWater SKY130, `sky130_fd_sc_hd`. Tools: Icarus Verilog, GTKWave, Yosys, OpenSTA, LibreLane (OpenROAD, Magic, KLayout, Netgen), all in the IIC-OSIC-TOOLS Docker image.
Example operands (Part A task 5): roll number 2026203012 -> A = 7, B = 9, P = 63 (0x3F).

## Repository layout

```
README.md
rtl/full_adder.v  rtl/mult_array.v
tb/tb_mult.v
synth/synth.tcl  synth/mult_array_netlist.v  synth/mult_array_stat.rpt
sta/sta.tcl      sta/mult_array_timing.rpt
pnr/config.json  pnr/metrics.json  pnr/mult_array.gds     (pnr/runs/ is not committed)
report/report.pdf  (+ logs, figures and the scripts in report/tools/ that generated the report)
```

All commands are run from the repository root inside the container (`/foss/designs/<project>`).

## Part A: RTL design and verification

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim            # PASS: 256 vectors checked, 0 errors
gtkwave mult.vcd
```

Fault test: `sum` in `rtl/full_adder.v` was temporarily changed to `a ^ b`, the same two commands were run (`FAIL: 256 vectors checked, 95 errors`, log in `report/partA_fail.log`), and the change was undone.

## Part B: logic synthesis

```bash
yosys -c synth/synth.tcl
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls            # FAIL: 256 vectors checked, 239 errors
iverilog -g2012 -DFUNCTIONAL -o gls tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls            # PASS: 256 vectors checked, 0 errors
```

With `-DUNIT_DELAY=#1` every gate has a 1 ns delay, which can make the combinational path longer than the 10 ns testbench clock; the run without it checks the function at zero gate delay.

| Metric | Value |
|---|---|
| Total number of cells | 63 |
| Number of flip-flops | 16 (dfrtp_1) |
| Total cell area (um2) | 740.710 |
| Flip-flop area (um2) | 400.384  (16 x 25.024) |
| Flip-flop area (% of total) | 54.05 % |
| 3 most-used cell types | dfrtp_1: 16, nand2_1: 8, a21oi_1: 6 |
| Netlist simulation result | see below (PASS line) |

## Part C: static timing analysis

```bash
sta -no_splash -exit sta/sta.tcl                 # T = 10 ns  -> worst slack 7.396 ns
T=2.60 sta -no_splash -exit sta/sta.tcl           # T = Tmin   -> slack 0.016 ns, writes sta/mult_array_timing.rpt
```

Tmin = 10 - 7.396 = 2.604, rounded up to 2.60 ns; Fmax = 384.6 MHz.

| Metric | Value |
|---|---|
| Worst slack at T = 10 ns (ns) | 7.396 |
| Tmin (ns) | 2.60 |
| Fmax (MHz) | 384.6 |
| Slack at T = Tmin (ns) | 0.016 |
| Critical path start point | _095_ = a_reg[1] |
| Critical path end point | _092_ = p[6] |
| Number of cells on critical path | 8 logic cells (10 with the two flip-flops) |
| Latency (ns) = 2 x Tmin | 5.20 |
| Throughput (million results/s) | 384.6 |

## Part D: physical design (LibreLane)

```bash
cd pnr
librelane config.json
```

`CLOCK_PERIOD` start value = 1.2 x Tmin rounded up to the next 0.5 ns, increased until all setup checks passed. Every run found in `pnr/` (settings from each run's `resolved.json`, results from its `final/metrics.json`; also in `report/attempts.csv`):

| Run | T (ns) | Synthesis strategy | Other settings | Setup WNS (ns) | Setup viol. | Hold WNS | Slew viol. | DRC | LVS | Result |
|---|---|---|---|---|---|---|---|---|---|---|
| runs/RUN_2026-10-24_14-01-01 | 3.5 | AREA 0 | SYNTH_STRATEGY=AREA 0 | -2.132 | 15 | 0.119 | 0 | 0 | 0 | setup/other FAIL |
| runs/delay2_test | 3.5 | DELAY 2 | - | -1.666 | 15 | 0.095 | 6 | 0 | 0 | setup/other FAIL |
| runs/delay4_test | 3.5 | DELAY 4 | SYNTH_STRATEGY=DELAY 4 | -2.714 | 15 | 0.107 | 11 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-24_20-05-46 | 3.5 | DELAY 2 | PL_RESIZER_SETUP_MAX_BUFFER_PCT=100; GRT_RESIZER_SETUP_MAX_BUFFER_PCT=100 | -1.666 | 15 | 0.095 | 6 | 0 | 0 | setup/other FAIL |
| runs/delay2_util80_test | 3.5 | DELAY 2 | PL_RESIZER_SETUP_MAX_UTIL_PCT=80; GRT_RESIZER_SETUP_MAX_UTIL_PCT=80 | -1.666 | 15 | 0.095 | 6 | 0 | 0 | setup/other FAIL |
| runs/delay2_keepbuf_test | 3.5 | DELAY 2 | PL_RESIZER_SETUP_BUFFER_REMOVAL=False; GRT_RESIZER_SETUP_BUFFER_REMOVAL=False | -1.666 | 15 | 0.095 | 6 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-24_21-15-52 | 3.5 | DELAY 2 | SYNTH_SIZING=True | -1.666 | 15 | 0.095 | 6 | 0 | 0 | setup/other FAIL |
| mfs3_test/runs/RUN_2026-10-24_21-47-34 | 3.5 | DELAY 2 | SYNTH_ABC_USE_MFS3=True | -1.777 | 15 | 0.065 | 11 | 0 | 0 | setup/other FAIL |
| mfs3_test/runs/RUN_2026-10-24_21-50-41 | 3.5 | DELAY 2 | SYNTH_ABC_USE_MFS3=True | -1.777 | 15 | 0.065 | 11 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-25_05-25-21 | 5.8 | DELAY 2 | - | -0.587 | 9 | 0.135 | 11 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-25_05-32-46 | 7.5 | DELAY 2 | - | 0.144 | 0 | 0.137 | 15 | 0 | 0 | PASS |
| runs/RUN_2026-10-25_05-59-40 | 7.5 | DELAY 2 | RUN_POST_GRT_DESIGN_REPAIR=True; GRT_DESIGN_REPAIR_MAX_SLEW_PCT=20 | 0.173 | 0 | 0.137 | 4 | 0 | 0 | PASS |
| runs/RUN_2026-10-25_06-06-56 | 7.5 | DELAY 2 | RUN_POST_GRT_DESIGN_REPAIR=True; GRT_DESIGN_REPAIR_MAX_SLEW_PCT=20 | 0.173 | 0 | 0.137 | 4 | 0 | 0 | PASS |
| runs/RUN_2026-10-25_06-13-56 | 4 | DELAY 2 | - | -1.166 | 15 | 0.134 | 6 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-25_06-30-48 | 4 | DELAY 2 | - | -1.166 | 15 | 0.134 | 6 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-25_06-36-14 | 5 | DELAY 2 | - | -0.353 | 9 | 0.136 | 6 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-25_06-41-37 | 5.5 | DELAY 2 | - | -0.484 | 9 | 0.137 | 6 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-25_06-47-13 | 6 | DELAY 2 | - | -0.624 | 9 | 0.137 | 15 | 0 | 0 | setup/other FAIL |
| runs/RUN_2026-10-25_07-03-11 | 7 | DELAY 2 | - | -0.356 | 7 | 0.137 | 15 | 0 | 0 | setup/other FAIL |
| runs/partD_3p5ns | 3.5 | DELAY 2 | - | -1.666 | 15 | 0.095 | 6 | 0 | 0 | setup/other FAIL |
| runs/partD_3p5ns_repair | 3.5 | DELAY 2 | RUN_POST_GRT_DESIGN_REPAIR=True; GRT_DESIGN_REPAIR_MAX_SLEW_PCT=20 | -1.639 | 15 | -0.354 | 0 | 0 | 0 | setup/other FAIL |
| runs/partD_3p5ns_delay3 | 3.5 | DELAY 3 | RUN_POST_GRT_DESIGN_REPAIR=True; SYNTH_STRATEGY=DELAY 3; GRT_DESIGN_REPAIR_MAX_SLEW_PCT=20 | -1.994 | 15 | -0.193 | 0 | 0 | 0 | setup/other FAIL |

Final run: `CLOCK_PERIOD = 7.5` ns. `pnr/metrics.json` and `pnr/mult_array.gds` were copied from that run's `final/` folder:

```bash
cp pnr/runs/<final-run>/final/metrics.json pnr/metrics.json
cp pnr/runs/<final-run>/final/gds/mult_array.gds pnr/mult_array.gds
```

| Metric | Value |
|---|---|
| CLOCK_PERIOD used (ns) | 7.5 |
| Number of runs needed | 22 LibreLane runs in total (all listed in Table 5); the first passing period was 7.5 ns |
| Core area (um2) | 17759.5 |
| Cells after synthesis (Part B) | 63 |
| Cells after place and route | 1961 instances in total = 386 standard cells (incl. 245 tap) + 1575 fill; 141 non-physical cells (logic, flip-flops, buffers) |
| Kinds of cells added | tap 245, fill 1575, timing-repair/IO buffers 27, clock buffers 3, decap 0 |
| Wirelength (um) | 3778 (routed), 967 vias |
| Setup slack (ns) | 0.173 (worst corner ss_100C_1v60); 3.714 typical corner |
| Post-route Fmax (MHz) | 136.5 (worst corner); 264.1 (typical corner) |
| Fmax from Part C (MHz) | 384.6 |
| DRC errors | Magic 0, KLayout 0, router 0; antenna violations 0 |
| LVS errors | 0 |
| Hold slack (ns) | 0.137, 0 violations |
| Max slew / cap / fanout violations | 4 / 0 / 0  (slew: only in the extreme slow corner, see note) |

Note on max-slew: the flow reports 4 maximum-slew violations, all in the max_ss_100C_1v60 corner (100 C, 1.60 V, slow transistors, worst-case RC). They are an additional electrical sign-off warning from the library's max_transition limit, not one of the assignment's pass criteria (DRC = 0, LVS = 0, setup slack >= 0). The typical corner has 0 slew, 0 cap and 0 fanout violations. We tried SYNTH_STRATEGY variants, SYNTH_SIZING, MFS3 and post-global-route design repair (see Table 5); because they changed timing or area without a clean result and relaxing limits only hides the warning, the submitted run keeps the plain flow.

Screenshots (`report/img/layout_full.png`, `report/img/layout_zoom.png`) were rendered with `klayout -b -r report/tools/klayout_shots.py`.

## Report

`report/report.pdf` (tables, figures and answers to the six questions) is generated from the files above with:

```bash
bash report/tools/run_bc.sh
python3 report/tools/make_report.py --mate-name "Polu Lohith Reddy" --mate-roll "2026203004"
```
