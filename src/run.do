quit -sim
file delete -force work

vlib work

vlog *.v

vsim -novopt tb

log -r /*

run -all