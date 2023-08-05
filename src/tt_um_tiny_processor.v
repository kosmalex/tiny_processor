`default_nettype none

`define CLOG2(x) \
  (x <= 2) ? 1 : \
  (x <= 4) ? 2 : \
  (x <= 8) ? 3 : \
  (x <= 16) ? 4 : \
  (x <= 32) ? 5 : \
  (x <= 64) ? 6 : \
  -1

`define DATAPATH_W 8
`define INST_W     8
`define IMEM_SZ    16
`define DMEM_SZ    13

module cache #(
  parameter SIZE = 8,

  localparam SIZE_W = `CLOG2(SIZE)
)(
  input wire clk, rst,

  input wire[`DATAPATH_W-1:0]  data_in,
  input wire[SIZE_W-1:0]       addr_in,
  input wire                   en_in,

  output wire[`DATAPATH_W-1:0] data_out
);

reg[`DATAPATH_W-1:0] mem[0:SIZE-1];

`ifdef FPGA_demo
  initial $readmemh("./init.mem", mem);
`endif

always @(posedge clk) begin
  if (en_in) mem[addr_in] <= data_in;
end

assign data_out = mem[addr_in];
endmodule

module shift_reg #(
  parameter SIZE = 8
)(
  input wire clk, rst,
  input wire sdata_in, // Serial data
  input wire en_in   ,  // Enable write and shift

  output wire[SIZE-1:0] data_out //parallel data output
);

reg[SIZE-1:0] register;

generate
  genvar i;

  for (i = 0; i < SIZE; i = i + 1) begin
    if (i == 0) begin
      always @(posedge clk) begin
        if (rst) begin
          register[SIZE - i - 1] <= 0;
        end else if (en_in) begin
          register[SIZE - i - 1] <= sdata_in;
        end
      end
    end else begin
      always @(posedge clk) begin
        if (rst) begin
          register[SIZE - i - 1] <= 0;
        end else if (en_in) begin
          register[SIZE - i - 1] <= register[SIZE - i];
        end
      end
    end
  end
endgenerate

assign data_out = register;
endmodule

module control_logic (
  input wire       clk, rst,

  input wire       display_in,

  input wire[3:0]  opcode_in,
  input wire[3:0]  pc_in,
  input wire[7:0]  alu_res_in,

  input wire       master2proc_en_in,
  input wire       csi, csd,

  output wire      proc_done_out,

  output wire      pc_sel_out,
  output wire      pc_en_out,
  output wire      pc_rst_out,

  output wire[2:0] unit_sel_out,
  output wire      op_sel_out,
  output wire      src_sel_out,
  output wire      mul_seg_sel,

  output wire      dcache_wen_out,
  output wire      icache_wen_out,
  output wire      icache_addr_sel_out,
  output wire      dcache_addr_sel_out,
  output wire      dcache_data_in_sel_out,

  output wire      buff_shen_out,

  output wire      acc_wen_out,

  output wire      display_on_out
);
parameter IDLE   = 2'b00;
parameter EXEC   = 2'b01;
parameter IRECV  = 2'b10;
parameter DRECV  = 2'b11;

wire master_wr;
assign master_wr = (~csi | ~csd) & ~master2proc_en_in;

// FSM //
reg[1:0] st;
always @(posedge clk) begin
  if (rst) begin
    st <= IDLE;
  end begin
    case (st)
      IDLE: begin
        if (master2proc_en_in)
          st <= EXEC;
        else if (~csi)
          st <= IRECV;
        else if (~csd)
          st <= DRECV;
      end

      EXEC: begin
        st <= (master2proc_en_in & pc_en_out) ? EXEC : IDLE;
      end

      IRECV: begin
        st <= ~csi ? IRECV : IDLE;
      end

      DRECV: begin
        st <= ~csd ? DRECV : IDLE;
      end

      default: st <= IDLE;
    endcase
  end
end

wire is_idle = ( st == IDLE );
wire is_exec = ( st == EXEC );

// Processor
assign proc_done_out = is_idle;

// Check if `bnez` branch is taken
wire is_branch   = &opcode_in;
wire is_not_zero = |alu_res_in;
wire is_taken    = is_branch & is_not_zero;

assign pc_sel_out = is_taken;

/** If the last instruction is not a branch or is a not taken branch -->
    the programm has terminated --> freeze `pc`.
 */
wire pc_last_val = &pc_in;
assign pc_en_out  = ~( pc_last_val & (~is_branch | ~is_taken) );

assign pc_rst_out = ~is_exec;

/**
  op_sel_out: Used to distinguish between addition-subtraction, 
              left-right shift, signed/unsigned multiply.
  src_sel_out: Operand select -> RS or SEXT immediate.
 */
assign op_sel_out  = opcode_in[2];
assign src_sel_out = opcode_in[3] & ~opcode_in[2] & ~mul_seg_sel;

wire unit_sel_1;
assign unit_sel_1 = &opcode_in[3:2]; /* Divides units into 2 categories:
                                     1> Those that do operate with immediates
                                     2> And those that do not */

wire[1:0] unit_sel_0;
assign unit_sel_0 = opcode_in[1:0]; /* Select between different ops in the category */

assign unit_sel_out = {unit_sel_1, unit_sel_0};

// Select the upper or lower segment of the mul result
assign mul_seg_sel = opcode_in[3] & ~opcode_in[2] & ~opcode_in[1] & opcode_in[0];

assign icache_wen_out      = ( st == IRECV ) & csi;
assign icache_addr_sel_out = icache_wen_out;

// Equivalent to `opcode_in == 4'h7`
wire temp;
assign temp = ( st == DRECV ) & csd;

assign dcache_wen_out = temp | ( &opcode_in[2:0] & is_exec);
assign dcache_addr_sel_out = temp;
assign dcache_data_in_sel_out = dcache_addr_sel_out;

// When storing, don't write accumulator register
assign acc_wen_out = ~dcache_wen_out & is_exec;

// Buffer shift register
assign buff_shen_out = master_wr;

// Seven segment
assign display_on_out = is_idle & display_in;
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

// 

// Processor global //
wire rst = ~rst_n;

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

// Shift register (8bit data and 4bit address --> tot: 12bits) //
wire[(`DATAPATH_W + 4)-1:0] buff_data;

/**
  SPI-interface: The slave is the processor.
 */
wire csd, csi;   // Chip select signals for data and instruction caches
wire miso, mosi; // Master In Slave Out and Master Out Slave In

// Master //
wire master_proc_en;
assign master_proc_en = uio_in[1] & uio_in[0]; 

// 7-seg //
wire      display_on_off       = ui_in[0]; // Basically freezes seven segment @ 0
wire[3:0] display_user_addr_in = ui_in[5:2];

// Control Signals //
wire      ctrl_proc_done;

wire      ctrl_pc_sel;
wire      ctrl_pc_en;
wire      ctrl_pc_rst;

wire[2:0] ctrl2alu_unit_sel;
wire      ctrl2alu_op_sel;
wire      ctrl_src_sel;
wire      ctrl2alu_mul_seg_sel;

wire      ctrl2dcache_wen;
wire      ctrl2icache_wen;
wire      ctrl_icache_addr_sel;
wire      ctrl_dcache_addr_sel;
wire      ctrl_dcache_data_in_sel;

wire      ctrl_acc_wen;

wire      ctrl_buff_shen;

wire      ctrl_display_on;

// Signal renaming
assign csi  = ~(~uio_in[1] &  uio_in[0]);
assign csd  = ~( uio_in[1] & ~uio_in[0]);
assign mosi = uio_in[2];

assign uio_out[3]   = ctrl_proc_done;

// Ground unused
assign uio_out[2:0] = 3'b0; 
assign uio_out[7:4] = 1'b0;

// Inputs
assign uio_oe[2:0] = 3'b0; // en, csi, csd, mosi

// Outputs
assign uio_oe[3]   = 3'h7; // done(uio_oe[3])
assign uio_oe[7:4] = 4'hF; // unsused

assign opcode = icache_data[3:0]; 

control_logic control_logic_0 (
  .clk          (clk),
  .rst          (rst),

  .display_in   (display_on_off),

  .opcode_in    (opcode ),
  .pc_in        (pc     ),
  .alu_res_in   (alu_res),

  .master2proc_en_in (master_proc_en),
  .csi               (csi           ),
  .csd               (csd           ),

  .proc_done_out (ctrl_proc_done),
  
  .pc_sel_out   (ctrl_pc_sel),
  .pc_en_out    (ctrl_pc_en ),
  .pc_rst_out   (ctrl_pc_rst),

  .unit_sel_out (ctrl2alu_unit_sel   ),
  .op_sel_out   (ctrl2alu_op_sel     ),
  .src_sel_out  (ctrl_src_sel        ),
  .mul_seg_sel  (ctrl2alu_mul_seg_sel),

  .dcache_wen_out         (ctrl2dcache_wen        ),
  .icache_wen_out         (ctrl2icache_wen        ),
  .icache_addr_sel_out    (ctrl_icache_addr_sel   ),
  .dcache_addr_sel_out    (ctrl_dcache_addr_sel   ),
  .dcache_data_in_sel_out (ctrl_dcache_data_in_sel),

  .buff_shen_out (ctrl_buff_shen),
  .acc_wen_out   (ctrl_acc_wen  ),

  .display_on_out (ctrl_display_on)
);

shift_reg #(
  .SIZE(`DATAPATH_W + 4)
)
buffer (
  .clk      (clk),
  .rst      (rst),

  .sdata_in (mosi),
  .en_in    (ctrl_buff_shen),

  .data_out (buff_data)
);

assign icache_addr = ctrl_icache_addr_sel ? buff_data[3:0] : pc; //(ctrl_display_on ? display_user_addr_in : pc);
cache #(
  .SIZE(`IMEM_SZ)
)
icache(
  .clk      (clk),
  .rst      (rst),

  .data_in  (buff_data[11:4]),
  .addr_in  (icache_addr),
  .en_in    (ctrl2icache_wen),

  .data_out (icache_data)
);

assign dcache_addr = ctrl_dcache_addr_sel ? buff_data[3:0] : 
                                            (ctrl_display_on ? display_user_addr_in : rs);
assign dcache_data_in = ctrl_dcache_data_in_sel ? buff_data[11:4] : acc;
cache #(
  .SIZE(`DMEM_SZ)
)
dcache(
  .clk      (clk),
  .rst      (rst),

  .data_in  (dcache_data_in),
  .addr_in  (dcache_addr),
  .en_in    (ctrl2dcache_wen),

  .data_out (dcache_data)
);

assign jmp = icache_data[7:4];
assign imm = icache_data[7:4];
assign rs  = icache_data[7:4];

// Early branch detect
assign pc_next = ctrl_pc_sel ? jmp : pc+1;
always @(posedge clk) begin
  if ( rst | ctrl_pc_rst ) begin
    pc <= 0;
  end else if (ctrl_pc_en) begin
    pc <= pc_next;
  end
end

// Execute-Writeback stage //
wire[`DATAPATH_W-1:0] sext_imm = {{4{imm[3]}}, imm};

assign src = ctrl_src_sel ? sext_imm : dcache_data;

// ALU //
alu alu_0 (
  .unit_sel_in (ctrl2alu_unit_sel),
  .op_sel_in   (ctrl2alu_op_sel),
  .mul_seg_sel (ctrl2alu_mul_seg_sel),

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

// Seven segment interface //
wire      msb;
wire[3:0] value;
// wire      view_sel;
// wire[7:0] view_data;

// assign view_sel  = ui_in[6];
// assign view_data = view_sel ? icache_data : dcache_data;

assign msb   = ui_in[1];
assign value = ctrl_display_on ? ( msb ? dcache_data[7:4] : dcache_data[3:0] ) : 4'h0;

seven_seg seven_seg_0 ( .value_in({msb, value}), .out(uo_out) );
endmodule