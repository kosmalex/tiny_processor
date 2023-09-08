`default_nettype none

`include "defs.vh"

module frame_cntr (
  input wire       clk, rst,
  input wire[31:0] data_in,
  input wire       cntr_rst_in,

  output wire     sig_out
);

reg[31:0] counter;

always @(posedge clk) begin
  if (rst) begin
    counter <= 0;
  end else if ( cntr_rst_in ) begin
      counter <= data_in;
    end else begin
      counter <= ( counter > 0 ) ? counter - 1 : counter;
    end
end

assign sig_out = |counter;
endmodule

module cache #(
  parameter SIZE = 8,
  parameter MODE = 1,

  localparam SIZE_W = `CLOG2(SIZE)
)(
  input wire clk,

  input wire[`DATAPATH_W-1:0] data_in,
  input wire[SIZE_W-1:0]      addr_in,
  input wire                  en_in,

  output wire[`DATAPATH_W-1:0] data_out,
  output wire[`DATAPATH_W-1:0] anim_reg_out,
  output wire[31:0]            frame_cntr_data_out
);

reg[`DATAPATH_W-1:0] mem[0:SIZE-1];

always @(posedge clk) begin
  if (en_in) mem[addr_in] <= data_in;
end

generate
  if (MODE == 1) begin
    wire valid_addr = ( addr_in < SIZE );

    assign data_out            = ~valid_addr ? 7'h0 : mem[addr_in];
    assign anim_reg_out        = mem[9];
    assign frame_cntr_data_out = {mem[13], mem[12], mem[11], mem[10]};
  end else begin
    assign data_out            = mem[addr_in];
    assign anim_reg_out        = 0;
    assign frame_cntr_data_out = 0;
  end 
endgenerate
endmodule

module control_logic (
  input wire       clk, rst,

  input wire[3:0]  opcode_in,
  input wire[3:0]  rs_in,
  input wire[3:0]  pc_in,
  input wire[7:0]  alu_res_in,

  input wire       master2proc_en_in,
  input wire       csi, csd,

  input wire       spi_if_ready_in,

  output wire      proc_done_out,

  output wire      pc_sel_out,
  output wire      pc_en_out,
  output wire      pc_rst_out,
  
  output wire      stall_out,

  output wire      spi_if_read_out,
  output wire      spi_if_send_out,
  output wire      spi_reg_sel_out,
  output wire      spi_if_driver_io_out,

  output wire[2:0] unit_sel_out,
  output wire      op_sel_out,
  output wire      src_sel_out,

  output wire      dcache_wen_out,
  output wire      icache_wen_out,
  output wire      icache_addr_sel_out,
  output wire      dcache_addr_sel_out,
  output wire      dcache_data_in_sel_out,

  output wire      acc_wen_out,

  output wire      frame_cntr_rst_out,
  output wire      frame_cntr_reg_sel_out
);
parameter IDLE  = 2'b00;
parameter EXEC  = 2'b01;
parameter IRECV = 2'b10;
parameter DRECV = 2'b11;

reg is_rid_15;

wire iwrite;
wire dwrite;

assign iwrite = ~csi; 
assign dwrite = ~csd;

reg[1:0] st;

// FSM //
always @(posedge clk) begin
  if (rst) begin
    st <= IDLE;
  end else begin
    case (st)
      IDLE: begin
        if (master2proc_en_in) begin
          st <= EXEC;
        end else if (iwrite) begin
          st <= IRECV;
        end else if (dwrite) begin
          st <= DRECV;
        end
      end

      IRECV: st <= csi ? IDLE : IRECV;
      DRECV: st <= csd ? IDLE : DRECV;

      EXEC: begin
        st <= (master2proc_en_in & pc_en_out) ? EXEC : IDLE;
      end

      default: st <= IDLE;
    endcase
  end
end

wire is_idle;
wire is_exec;

assign is_idle = ( st == IDLE );
assign is_exec = ( st == EXEC );

// Processor
assign proc_done_out = is_idle;

// Check if `bnez` branch is taken
wire is_branch  ;
wire is_not_zero;
wire is_taken   ;

assign is_branch   = &opcode_in;
assign is_not_zero = |alu_res_in;
assign is_taken    = is_branch & is_not_zero;

wire is_jump;
assign is_jump = opcode_in[3] & ~opcode_in[2] & ~opcode_in[1] & opcode_in[0];

assign pc_sel_out = is_taken | is_jump;

/** If the last instruction is not a branch or is a not taken branch -->
    the programm has terminated --> freeze `pc`.
 */
wire pc_last_val;
assign pc_last_val =  &pc_in;
assign pc_en_out   = ~( pc_last_val & (~is_branch | ~is_taken | ~is_jump) );

assign pc_rst_out = ~is_exec;

/**
  op_sel_out: Used to distinguish between addition-subtraction, 
              left-right shift, signed/unsigned multiply.
  src_sel_out: Operand select -> RS or SEXT immediate.
 */
assign op_sel_out  = opcode_in[2];
assign src_sel_out = opcode_in[3] & ~opcode_in[2] & ~is_jump;

wire unit_sel_1;
assign unit_sel_1 = &opcode_in[3:2]; /* Divides units into 2 categories:
                                     1> Those that do operate with immediates
                                     2> And those that do not */

wire[1:0] unit_sel_0;
assign unit_sel_0 = opcode_in[1:0]; /* Select between different ops in the category */

assign unit_sel_out = {unit_sel_1, unit_sel_0};

wire is_spi_io;
assign is_spi_io = ( (~opcode_in[3] & ~opcode_in[2]) | (~opcode_in[3] & opcode_in[2]) ) & ~opcode_in[1] & opcode_in[0];

assign stall_out = is_spi_io & ~spi_if_ready_in & is_exec;

// Send or read
assign spi_if_send_out = ~opcode_in[2] & is_spi_io & is_exec;
assign spi_if_read_out = ( (iwrite | dwrite) & ~master2proc_en_in ) | ( opcode_in[2] & is_spi_io & is_exec ); // <- second half is problematic

// Select the spi register as a source register
assign spi_reg_sel_out = rs_in[3] & rs_in[2] & rs_in[1] & ~rs_in[0];

assign spi_if_driver_io_out = ~is_exec;

assign icache_wen_out      = ( st == IRECV ) & csi;
assign icache_addr_sel_out = icache_wen_out;

// Did we stop receiving data from master ?
wire temp;
assign temp = ( st == DRECV ) & csd;

wire is_rf_wr;
assign is_rf_wr = ( ~opcode_in[3] & &opcode_in[2:0] ); 

assign dcache_wen_out         = ( temp | ( is_rf_wr & is_exec ) ) & ~stall_out;
assign dcache_addr_sel_out    = temp;
assign dcache_data_in_sel_out = dcache_addr_sel_out;

assign frame_cntr_rst_out = (is_exec & is_branch & ~is_taken & is_rid_15) | ( is_idle & master2proc_en_in);

assign frame_cntr_reg_sel_out = rs_in[3] & rs_in[2] & rs_in[1] & rs_in[0];

/**
  If a `la x15` precedes a `bnez {label}` instruction, it means
  that the frame counter of the seven segment should be reseted.
  `is_rid_15` signal is used to indentify the above order of
  instructions.
 */
always @(posedge clk) begin
  if (rst)
    is_rid_15 <= 0;
  else
    is_rid_15 <= frame_cntr_reg_sel_out;
end

// Don't write accumulator register
assign acc_wen_out = ~dcache_wen_out & is_exec & ~is_spi_io & ~(is_branch | is_jump) & ~stall_out;

endmodule

module tt_um_tiny_processor (
  input  wire[7:0] ui_in,   // Dedicated inputs - connected to the input switches
  output wire[7:0] uo_out,  // Dedicated outputs - connected to the 7 segment display

  input  wire[7:0] uio_in,  // IOs: Bidirectional Input path
  output wire[7:0] uio_out, // IOs: Bidirectional Output path
  output wire[7:0] uio_oe,  // IOs: Bidirectional Enable path (active high: 0=input, 1=output)

  input  wire      ena,     // will go high when the design is enabled
  input  wire      clk,     // clock
  input  wire      rst_n    // reset_n - low to reset
);
localparam PC_W  = `CLOG2(`IMEM_SZ);
localparam RID_W = `CLOG2(`DMEM_SZ);
localparam OPC_W = 4;

// Processor global //
wire rst;
assign rst = ~rst_n;

// Fetch-Decode //
reg [PC_W-1:0]  pc;
wire[PC_W-1:0]  pc_next;
wire[PC_W-1:0]  jmp;
wire[RID_W-1:0] rs;
wire[3:0]       imm;
wire[3:0]       opcode;

// ALU //
wire[`DATAPATH_W-1:0] src;
reg[`DATAPATH_W-1:0]  acc;
wire[`DATAPATH_W-1:0] alu_res;

// Caches //
wire[`DATAPATH_W-1:0] dcache_data;
wire[`DATAPATH_W-1:0] icache_data;

wire[3:0] icache_addr;
wire[3:0] dcache_addr;

wire[`DATAPATH_W-1:0] dcache_data_in;

// SPI-interface //
wire csd, csi;   // Chip select signals for data and instruction caches
wire miso, mosi; // Master In Slave Out and Master Out Slave In

// SPI //
wire[RID_W-1:0]       spi_if_addr;
wire[`DATAPATH_W-1:0] spi_if_data;
wire                  spi_if2ctrl_ready;

// Master //
wire master_proc_en;
assign master_proc_en = uio_in[1] & uio_in[0]; 

// Frame counter //
wire       frame_cntr_reg_val;
wire[31:0] frame_cntr_data;

// 7-seg //
wire      display_on_off      ;
wire      msb                 ;
wire[3:0] display_user_addr_in;
wire      view_sel            ;
wire      anim_en             ;

assign display_on_off       = ui_in[0]; // Basically freezes seven segment @ 0
assign msb                  = ui_in[1];  
assign display_user_addr_in = ui_in[5:2];
assign view_sel             = ui_in[6];
assign anim_en              = ui_in[7];

wire[`DATAPATH_W-1:0] anim_reg;

// Control Signals //
wire      ctrl_proc_done;

wire      ctrl_pc_sel;
wire      ctrl_pc_en;
wire      ctrl_pc_rst;

wire      ctrl_stall;

wire[2:0] ctrl2alu_unit_sel;
wire      ctrl2alu_op_sel;
wire      ctrl_src_sel;

wire      ctrl2dcache_wen;
wire      ctrl2icache_wen;
wire      ctrl_icache_addr_sel;
wire      ctrl_dcache_addr_sel;
wire      ctrl_dcache_data_in_sel;

wire      ctrl_acc_wen;

wire      ctrl2frame_cntr_rst;
wire      ctrl_frame_cntr_reg_sel;

wire      ctrl2spi_if_read;
wire      ctrl2spi_if_send;
wire      ctrl_spi_reg_sel;
wire      ctrl2spi_if_driver_io;

// SPI
assign csi        = ~( ~uio_in[1] &  uio_in[0] );
assign csd        = ~(  uio_in[1] & ~uio_in[0] );
assign miso       = uio_in[4];
assign uio_out[2] = ctrl_proc_done;
assign uio_out[5] = mosi;

// Ground unused
assign uio_out[1:0] = 3'b0; 
assign uio_out[4]   = 1'b0;

// Inputs
assign uio_oe[1:0] = 2'b0; // ctrl[1:0]
assign uio_oe[4]   = 1'b0; // miso

// Outputs
assign uio_oe[3:2] = 2'b11; // done(uio_oe[2]), sclk
assign uio_oe[6:5] = 2'b11; // mosi, cs
assign uio_oe[7]   = 1'b1;  // sync

assign opcode = icache_data[3:0];

// Buffer the `sync` output signal
reg bfrd_fcrv;
always @(posedge clk) begin
  if (rst) begin
    bfrd_fcrv <= 1'b1;
  end else begin
    bfrd_fcrv <= frame_cntr_reg_val;
  end
end
assign uio_out[7] = bfrd_fcrv;

control_logic control_logic_0 (
  .clk        (clk ),
  .rst        (rst),

  .opcode_in  (opcode ),
  .rs_in      (rs     ),
  .pc_in      (pc     ),
  .alu_res_in (alu_res),

  .master2proc_en_in (master_proc_en   ),
  .csi               (csi              ),
  .csd               (csd              ),
  .spi_if_ready_in   (spi_if2ctrl_ready),

  .proc_done_out (ctrl_proc_done),
  
  .pc_sel_out (ctrl_pc_sel),
  .pc_en_out  (ctrl_pc_en ),
  .pc_rst_out (ctrl_pc_rst),

  .stall_out (ctrl_stall),

  .spi_if_read_out      (ctrl2spi_if_read),
  .spi_if_send_out      (ctrl2spi_if_send),
  .spi_reg_sel_out      (ctrl_spi_reg_sel),
  .spi_if_driver_io_out (ctrl2spi_if_driver_io),

  .unit_sel_out (ctrl2alu_unit_sel),
  .op_sel_out   (ctrl2alu_op_sel  ),
  .src_sel_out  (ctrl_src_sel     ),

  .dcache_wen_out         (ctrl2dcache_wen        ),
  .icache_wen_out         (ctrl2icache_wen        ),
  .icache_addr_sel_out    (ctrl_icache_addr_sel   ),
  .dcache_addr_sel_out    (ctrl_dcache_addr_sel   ),
  .dcache_data_in_sel_out (ctrl_dcache_data_in_sel),

  .acc_wen_out (ctrl_acc_wen),

  .frame_cntr_rst_out     (ctrl2frame_cntr_rst    ),
  .frame_cntr_reg_sel_out (ctrl_frame_cntr_reg_sel)
);

spi_if spi_if_0 (
  .clk  (clk),
  .rst  (rst),

  .driver_io_in (ctrl2spi_if_driver_io),
  .addr_out     (spi_if_addr          ),

  .read_in   (ctrl2spi_if_read ),
  .ready_out (spi_if2ctrl_ready),
  .data_out  (spi_if_data      ),
  
  .send_in   (ctrl2spi_if_send),
  .data_in   (alu_res         ),
  
  .sclk_out  (uio_out[3]),
  .miso_in   (miso      ),
  .mosi_out  (mosi      ),
  .cs_out    (uio_out[6])
);

assign icache_addr = ctrl_icache_addr_sel ? spi_if_addr :
                                            (ctrl_proc_done ? display_user_addr_in : pc);
cache #(
  .SIZE(`IMEM_SZ),
  .MODE(    0   )
)
icache(
  .clk      (clk),
  
  .data_in  (spi_if_data),
  .addr_in  (icache_addr),
  .en_in    (ctrl2icache_wen),

  .data_out (icache_data)
);

assign dcache_addr = ctrl_dcache_addr_sel ? spi_if_addr :
                                            (ctrl_proc_done ? display_user_addr_in : rs);
assign dcache_data_in = ctrl_dcache_data_in_sel ? spi_if_data : acc;
cache #(
  .SIZE(`DMEM_SZ)
)
dcache(
  .clk      (clk),

  .data_in  (dcache_data_in),
  .addr_in  (dcache_addr),
  .en_in    (ctrl2dcache_wen),

  .data_out (dcache_data),
  
  .anim_reg_out (anim_reg),
  
  .frame_cntr_data_out (frame_cntr_data)
);

assign jmp = icache_data[7:4];
assign imm = icache_data[7:4];
assign rs  = icache_data[7:4];

// Branch detect
assign pc_next = ctrl_pc_sel ? jmp : pc+1;
always @(posedge clk) begin
  if ( rst | ctrl_pc_rst ) begin
    pc <= 0;
  end else if (ctrl_pc_en & ~ctrl_stall) begin
    pc <= pc_next;
  end
end

// Execute-Writeback stage //
wire[`DATAPATH_W-1:0] sext_imm;
assign sext_imm = {{4{imm[3]}}, imm};

assign src = ctrl_src_sel ? sext_imm : 
                            (ctrl_frame_cntr_reg_sel ? {7'b0, frame_cntr_reg_val} :
                                                       (ctrl_spi_reg_sel ? spi_if_data : dcache_data ) );

// ALU //
alu alu_0 (
  .unit_sel_in (ctrl2alu_unit_sel),
  .op_sel_in   (ctrl2alu_op_sel),

  .acc_in      (acc),
  .src_in      (src),

  .alu_res_out (alu_res)
);

always @(posedge clk) begin : Accumulator
  if ( rst ) begin
    acc <= 0;
  end else if (ctrl_acc_wen) begin
    acc <= alu_res;
  end
end

// Animation counter //
frame_cntr frame_cntr_0 (
  .clk (clk),
  .rst (rst),

  .data_in (frame_cntr_data),
  
  .cntr_rst_in (ctrl2frame_cntr_rst),
  .sig_out     (frame_cntr_reg_val)
);

// Seven segment interface //
wire[3:0] value;
wire[7:0] view_data;

assign view_data = view_sel ? icache_data    : dcache_data;
assign value     = msb      ? view_data[7:4] : view_data[3:0];

seven_seg seven_seg_0 (
  .value_in     ({msb, value}),
  .bit_array_in (anim_reg    ),
  .anim_en_in   (anim_en     ),
  .out          (uo_out      ),

  .display_on_in (display_on_off)
);

endmodule