
vlib work
vlog tb.sv
vsim -voptargs="+acc" tb
add wave -position insertpoint sim:/tb/*
run -all
