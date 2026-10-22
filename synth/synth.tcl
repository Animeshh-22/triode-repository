# Part B: SKY130 HD synthesis for the 4-bit array multiplier

# Read RTL and select the top-level design
read_verilog rtl/full_adder.v rtl/mult_array.v
hierarchy -check -top mult_array

# Synthesize generic logic
synth -top mult_array -flatten -noabc

# Map flip-flops to SKY130 HD cells
dfflibmap -liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Map combinational logic to SKY130 HD cells
abc -liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Clean and verify the mapped design
clean
check

# Save cell statistics and mapped netlist
tee -o synth/mult_array_stat.rpt stat -liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
write_verilog -noattr -noexpr synth/mult_array_netlist.v
