quit -sim
file delete -force work

vlib work

vlog *.v *.sv

vsim -novopt tbq

log -r /*
do ./waves/wave.do

run -all