onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/rst
add wave -noupdate -expand -group Driver /tb/dut/st
add wave -noupdate -expand -group Driver /tb/dut/bytes_sent
add wave -noupdate -expand -group Driver /tb/dut/drive
add wave -noupdate -expand -group Driver /tb/dut/done_in
add wave -noupdate -expand -group Driver /tb/dut/sclk_out
add wave -noupdate -expand -group Driver /tb/dut/rst_n_out
add wave -noupdate -expand -group Driver /tb/dut/mosi_out
add wave -noupdate -expand -group Driver /tb/dut/mode_out
add wave -noupdate -expand -group Driver /tb/dut/data
add wave -noupdate -expand -group Driver /tb/dut/bits_sent_en
add wave -noupdate -expand -group Driver /tb/dut/bits_sent
add wave -noupdate -expand -group Driver /tb/dut/bytes_sent_en
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/clk
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/rst_n
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/icache/mem
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/master2proc_en_in
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/csi
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/st
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/control_logic_0/master_wr
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/dcache/mem
add wave -noupdate -expand -group Processor -divider ShiftReg
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/buffer/data_out
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/opcode
add wave -noupdate -expand -group Processor /tb/tt_um_tiny_processor/pc
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/unit_sel_in
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/op_sel_in
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/mul_seg_sel
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/acc_in
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/src_in
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/alu_res_out
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/add_res
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/imul_res
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/mul_res
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/shift_res
add wave -noupdate -expand -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/alu_res
add wave -noupdate -expand -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/data_in
add wave -noupdate -expand -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/sel_in
add wave -noupdate -expand -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/en_in
add wave -noupdate -expand -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/cntr_rst_in
add wave -noupdate -expand -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/sig_out
add wave -noupdate -expand -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/buff
add wave -noupdate -expand -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/counter
add wave -noupdate -expand -group Ctrl /tb/tt_um_tiny_processor/ctrl_frame_cntr_reg_sel
add wave -noupdate -expand -group Ctrl /tb/tt_um_tiny_processor/ctrl_src_sel
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {17005000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 214
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
WaveRestoreZoom {14940746 ps} {19591066 ps}
