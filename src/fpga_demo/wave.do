onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/rst
add wave -noupdate -expand -group Driver /tb/dut/st
add wave -noupdate -expand -group Driver /tb/dut/bytes_sent
add wave -noupdate -expand -group Driver /tb/dut/drive
add wave -noupdate -expand -group Driver /tb/dut/done_in
add wave -noupdate -expand -group Driver /tb/dut/mosi_out
add wave -noupdate -expand -group Driver /tb/dut/mode_out
add wave -noupdate -expand -group Driver /tb/dut/data
add wave -noupdate -expand -group Driver /tb/dut/bits_sent_en
add wave -noupdate -expand -group Driver /tb/dut/bits_sent
add wave -noupdate -expand -group Driver /tb/dut/bytes_sent_en
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/rst_n
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/icache/mem
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/control_logic_0/master2proc_en_in
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/control_logic_0/pc_en_out
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/control_logic_0/csi
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/control_logic_0/st
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/dcache/mem
add wave -noupdate -group Processor -divider ShiftReg
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/opcode
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/pc
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/ctrl_stall
add wave -noupdate -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/acc_in
add wave -noupdate -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/src_in
add wave -noupdate -group Processor -expand -group ALU /tb/tt_um_tiny_processor/alu_0/alu_res
add wave -noupdate -group Processor /tb/tt_um_tiny_processor/uo_out
add wave -noupdate -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/data_in
add wave -noupdate -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/cntr_rst_in
add wave -noupdate -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/sig_out
add wave -noupdate -group FrameCntr /tb/tt_um_tiny_processor/frame_cntr_0/counter
add wave -noupdate -group Ctrl /tb/tt_um_tiny_processor/ctrl_frame_cntr_reg_sel
add wave -noupdate -group Ctrl /tb/tt_um_tiny_processor/ctrl_src_sel
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/addr_out
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/read_in
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/send_in
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/ready_out
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/data_out
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/data_in
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/sclk_out
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/miso_in
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/mosi_out
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/cs_out
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/nbytes
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/sr_en
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/sr_mode
add wave -noupdate -group SPI_if /tb/tt_um_tiny_processor/spi_if_0/st
add wave -noupdate -group SR /tb/tt_um_tiny_processor/spi_if_0/shift_reg_0/sdata_in
add wave -noupdate -group SR /tb/tt_um_tiny_processor/spi_if_0/shift_reg_0/en_in
add wave -noupdate -group SR /tb/tt_um_tiny_processor/spi_if_0/shift_reg_0/en_shft_in
add wave -noupdate -group SR /tb/tt_um_tiny_processor/spi_if_0/shift_reg_0/mode_in
add wave -noupdate -group SR /tb/tt_um_tiny_processor/spi_if_0/shift_reg_0/data_in
add wave -noupdate -group SR /tb/tt_um_tiny_processor/spi_if_0/shift_reg_0/data_out
add wave -noupdate -group SR /tb/tt_um_tiny_processor/spi_if_0/shift_reg_0/register
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7599919 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 172
configure wave -valuecolwidth 43
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
WaveRestoreZoom {361875 ps} {1053552 ps}
