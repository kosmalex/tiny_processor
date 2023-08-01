onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/rst
add wave -noupdate -expand -group Driver /tb/dut/st
add wave -noupdate -expand -group Driver /tb/dut/drive
add wave -noupdate -expand -group Driver /tb/dut/done_in
add wave -noupdate -expand -group Driver /tb/dut/sclk_out
add wave -noupdate -expand -group Driver /tb/dut/rst_n_out
add wave -noupdate -expand -group Driver /tb/dut/mosi_out
add wave -noupdate -expand -group Driver /tb/dut/mode_out
add wave -noupdate -expand -group Driver /tb/dut/mem
add wave -noupdate -expand -group Driver /tb/dut/data
add wave -noupdate -expand -group Driver /tb/dut/bits_sent_en
add wave -noupdate -expand -group Driver /tb/dut/bits_sent
add wave -noupdate -expand -group Driver /tb/dut/bytes_sent_en
add wave -noupdate -expand -group Driver /tb/dut/bytes_sent
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/clk
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/rst_n
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/icache/mem
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/master2proc_en_in
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/csi
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/st
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/master_wr
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/dcache/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5192455 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {5140961 ps} {5447451 ps}
