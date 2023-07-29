onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tbq/clk
add wave -noupdate /tbq/rst_n
add wave -noupdate -expand -group Proc_state /tbq/tt_um_tiny_processor/pc
add wave -noupdate -expand -group Proc_state -radix symbolic /tbq/tt_um_tiny_processor/control_logic_0/st
add wave -noupdate -expand -group Proc_state /tbq/tt_um_tiny_processor/master_proc_en
add wave -noupdate -expand -group Proc_state /tbq/done
add wave -noupdate -expand -group SPI /tbq/tt_um_tiny_processor/csd
add wave -noupdate -expand -group SPI /tbq/tt_um_tiny_processor/csi
add wave -noupdate -expand -group SPI /tbq/tt_um_tiny_processor/mosi
add wave -noupdate -expand -group SPI /tbq/tt_um_tiny_processor/ctrl_icache_addr_sel
add wave -noupdate -expand -group SPI /tbq/tt_um_tiny_processor/ctrl2icache_wen
add wave -noupdate -expand -group SPI /tbq/tt_um_tiny_processor/ctrl_buff_shen
add wave -noupdate -expand -group SPI /tbq/tt_um_tiny_processor/buff_data
add wave -noupdate -expand -group Icache /tbq/tt_um_tiny_processor/icache/mem
add wave -noupdate -expand -group EXEC /tbq/tt_um_tiny_processor/opcode
add wave -noupdate -expand -group EXEC /tbq/tt_um_tiny_processor/rs
add wave -noupdate -expand -group EXEC /tbq/tt_um_tiny_processor/imm
add wave -noupdate -expand -group EXEC /tbq/tt_um_tiny_processor/src
add wave -noupdate -expand -group EXEC /tbq/tt_um_tiny_processor/acc
add wave -noupdate -expand -group EXEC /tbq/tt_um_tiny_processor/alu_res
add wave -noupdate -expand -group EXEC /tbq/tt_um_tiny_processor/dcache_data
add wave -noupdate -expand -group Dcache -radix decimal -childformat {{{/tbq/tt_um_tiny_processor/dcache/mem[0]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[1]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[2]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[3]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[4]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[5]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[6]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[7]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[8]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[9]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[10]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[11]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[12]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[13]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[14]} -radix decimal} {{/tbq/tt_um_tiny_processor/dcache/mem[15]} -radix decimal}} -subitemconfig {{/tbq/tt_um_tiny_processor/dcache/mem[0]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[1]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[2]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[3]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[4]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[5]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[6]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[7]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[8]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[9]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[10]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[11]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[12]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[13]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[14]} {-height 15 -radix decimal} {/tbq/tt_um_tiny_processor/dcache/mem[15]} {-height 15 -radix decimal}} /tbq/tt_um_tiny_processor/dcache/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5327399 ps} 0}
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
configure wave -timelineunits ps
update
WaveRestoreZoom {5259070 ps} {5528470 ps}
