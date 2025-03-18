
vlib work
vlog tb.sv
vsim -voptargs="+acc" tb_memory
add wave -position insertpoint sim:/tb_memory/*
run -all
