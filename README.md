# 4-bit Array Multiplier — RTL to GDSII

## Project Information

- **Student:** Animesh Pandey
- **Program:** M.Tech VLSI
- **Roll Number:** 2026203012
- **Team:** Triode
- **Technology:** SKY130 PDK (`sky130_fd_sc_hd`)

## Project Overview

This project implements a 4-bit unsigned array multiplier in Verilog RTL and develops it through an ASIC design flow targeting the SKY130 standard-cell library.

The planned flow includes:

1. RTL design and functional verification
2. Logic synthesis
3. Static timing analysis (STA)
4. Physical design
5. Layout verification and GDSII generation

## Part A — RTL Design and Functional Verification

### Design Architecture

The multiplier accepts two 4-bit unsigned operands, `a` and `b`, and produces an 8-bit product, `p`.

- **Inputs:** `a[3:0]`, `b[3:0]`
- **Output:** `p[7:0]`
- **Clock:** `clk`
- **Reset:** `rst_n`, asynchronous and active-low
- **Partial products:** 16 AND operations
- **Addition stages:** 12 full-adder instances
- **Registers:** Input operand registers and an output product register

The design uses registered inputs, combinational multiplication logic, and a registered output. The testbench accounts for the two-clock-edge input-to-output latency.

### Source Files

| File | Description |
|---|---|
| `rtl/full_adder.v` | Full-adder module |
| `rtl/mult_array.v` | 4-bit array multiplier |
| `tb/tb_full_adder.v` | Full-adder testbench |
| `tb/tb_mult.v` | Multiplier testbench |

### Functional Simulation

The multiplier testbench exhaustively checks all 256 combinations of the two 4-bit unsigned inputs. It also generates `mult.vcd` for waveform inspection.

Compile the RTL and testbench from the repository root:

```bash
iverilog -g2012 -s tb_mult -o /tmp/tb_mult \
    rtl/full_adder.v rtl/mult_array.v tb/tb_mult.v
```

Run the simulation:

```bash
vvp /tmp/tb_mult
```

Expected successful summary:

```text
PASS: 256 vectors checked, 0 errors
```

The passing simulation log is saved as `report/partA_pass.log`.

### Fault-Injection Verification

To verify that the testbench detects design errors, the full-adder sum equation was temporarily modified to ignore the carry input `cin`.

Faulty equation:

```verilog
assign sum = a ^ b;
```

Correct equation restored in the final RTL:

```verilog
assign sum = a ^ b ^ cin;
```

The intentional fault produced incorrect multiplier outputs, which were detected by the testbench.

- `report/partA_fail.log` — faulty run; 95 mismatches detected.
- `report/partA_pass.log` — corrected run; 256 vectors checked with zero errors.

The final committed RTL contains the corrected full-adder implementation.

### Waveform

The multiplier testbench generates `mult.vcd`. This waveform can be opened using GTKWave:

```bash
gtkwave mult.vcd
```

The waveform is used to inspect the clock, reset, input operands, registered output, and pipeline latency.

## Repository Structure

```text
triode-repository/
├── README.md
├── rtl/
│   ├── full_adder.v
│   └── mult_array.v
├── tb/
│   ├── tb_full_adder.v
│   └── tb_mult.v
├── synth/
├── sta/
├── pnr/
├── report/
│   ├── partA_fail.log
│   └── partA_pass.log
└── mult.vcd
```

The `synth/`, `sta/`, and `pnr/` stages are to be populated with their generated artifacts as the project progresses.

## Reproducibility

Run the compilation and simulation commands from the repository root. The testbench uses a 10 ns clock period and writes its waveform to `mult.vcd`.

## Project Status

- **Part A:** RTL implementation, exhaustive multiplier simulation, and intentional fault-injection evidence committed.
- **Part B:** Logic synthesis and gate-level verification pending.
- **Part C:** Static timing analysis pending.
- **Part D:** Physical design, layout verification, and GDSII generation pending.
