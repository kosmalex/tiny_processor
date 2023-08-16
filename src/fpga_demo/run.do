quit -sim
file delete -force work

vlog *.sv ../*.v

vsim tb -novopt

log -r /*

do wave.do

run -all
run 10us
