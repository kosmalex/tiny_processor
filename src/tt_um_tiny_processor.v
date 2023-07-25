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
`define DMEM_SZ    15

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

always @(posedge clk) begin
  if (rst) begin
      {mem[0], mem[1], mem[2], mem[3], mem[4], mem[5], mem[6], mem[7]} <= 0;
      {mem[9], mem[10], mem[11], mem[12], mem[13], mem[14], mem[15]} <= 0;
  end else begin
    if (en_in) mem[addr_in] <= data_in;
  end
end

assign data_out = mem[addr_in];
endmodule

module shift_reg #(
  parameter SIZE = 8
)(
  input wire sclk   ,  // Master clock (FPGA)
  input wire sdata_in, // Serial data
  input wire en_in  ,  // Enable write and shift

  output wire[SIZE-1:0] data_out //parallel data output
);

reg[SIZE-1:0] register;

generate
  genvar i;

  for (i = SIZE-1; i > 0; i = i - 1) begin : shift_reg_SIZEm2_0
    if ( i == (SIZE-1) ) begin
      always @(posedge sclk) begin
        if (en_in) begin
            register[i] <= sdata_in;
        end
      end
    end else begin
      always @(posedge sclk) begin
        if (en_in) begin
          register[i-1] <= register[i];
        end
      end
    end
  end
endgenerate

assign data_out = register;
endmodule

module control_logic (
  input wire       clk, rst,

  input wire[3:0]  opcode_in,
  input wire[3:0]  pc_in,
  input wire[7:0]  alu_res_in,

  input wire       master_en_proc_in,
  input wire       master_wr_in,

  output wire      pc_sel_out,
  output wire      pc_en_out,
  output wire      pc_rst_out,

  output wire[2:0] unit_sel_out,
  output wire      op_sel_out,
  output wire      src_sel_out,

  output wire      dcache_wen_out,
  output wire      icache_wen_out,

  output wire      buff_shen_out,

  output wire      acc_wen_out
);
parameter IDLE  = 2'b00;
parameter EXEC  = 2'b01;
parameter RECV  = 2'b10;
parameter WRITE = 2'b11;

reg[1:0] st;

// FSM for SPI interface //
always @(posedge clk) begin
  if (rst) begin
    st <= IDLE;
  end begin
    case (st)
      IDLE: begin
        st <= master_en_proc_in ? EXEC : IDLE;
        st <= master_wr_in ? RECV : IDLE;
      end

      EXEC: begin
        st <= master_en_proc_in ? EXEC : IDLE;
      end

      RECV: begin
        st <= master_wr_in ? RECV : WRITE;
      end

      WRITE: begin
        st <= IDLE;
      end

      default: st <= IDLE;
    endcase
  end
end

// Check if `bnez` branch is taken
wire is_branch   = &opcode_in;
wire is_not_zero = |alu_res_in;
wire is_taken    = is_branch & is_not_zero;

assign pc_sel_out = is_taken;

/** If the last instruction is not a branch or is a not taken branch -->
    the programm has terminated --> freeze `pc`.
 */
assign pc_en_out  = ~( &pc_in & (~is_branch | ~is_taken) );

assign pc_rst_out = ( st != EXEC );

/**
  op_sel_out: Used to distinguish between addition-subtraction, 
              left-right shift, `and` and `nand` logic ops.
  src_sel_out: Operand select -> RS or SEXT immediate
 */
assign op_sel_out  = opcode_in[2];
assign src_sel_out = opcode_in[3] & ~opcode_in[2];

wire unit_sel_1 = &opcode_in[3:2]; /* Divides units into 2 categories:
                                     1> Those that do operate with immediates
                                     2> And those that do not */

wire[1:0] unit_sel_0 = opcode_in[1:0]; /* Select between different ops in the category */

assign unit_sel_out = {unit_sel_1, unit_sel_0};

// Equivalent to `opcode_in == 4'h7`;
assign dcache_wen_out = &opcode_in[2:0] && ( st == EXEC );
assign icache_wen_out = ( st == WRITE );

// When storing, don't write accumulator register
assign acc_wen_out = ~dcache_wen_out && ( st == EXEC );

// Buffer shift register
assign buff_shen_out = ( st == RECV );
endmodule

module tt_um_tiny_processor (
  input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
  output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display

  input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
  output wire [7:0] uio_out,  // IOs: Bidirectional Output path
  output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)

  input  wire       ena,      // will go high when the design is enabled
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);
localparam PC_W  = `CLOG2(`IMEM_SZ);
localparam RID_W = `CLOG2(`DMEM_SZ);
localparam OPC_W = 4;

// Processor global //
wire rst = ~rst_n;

// Fetch-Decode //
reg [PC_W-1:0]  pc;
wire[PC_W-1:0]  pc_next;
wire[PC_W-1:0]  jmp;
wire[RID_W-1:0] rs;
wire[3:0]       imm;

// ALU //
wire[`DATAPATH_W-1:0] src;
reg[`DATAPATH_W-1:0]  acc;
wire[`DATAPATH_W-1:0] alu_res;
reg[`DATAPATH_W-1:0]  op_data;

// Caches //
wire[`DATAPATH_W-1:0] dcache_data;
wire[`DATAPATH_W-1:0] icache_data;

// Shift register (8bit data and 4bit address --> tot: 12bits) //
wire[(`DATAPATH_W + 4)-1:0] sr_data;

/**
  SPI-interface: The slave is the processor. The master operates
    with the slaves clock freq.
 */
wire csd, csi;   // Chip select signals for data and instruction caches
wire sclk;       // Serial clock
wire miso, mosi; // Master In Slave Out and Master Out Slave In

assign csi  = uio_in[1];
assign csd  = uio_in[2];
assign mosi = uio_in[3];

assign uio_out[4] = sr_data[0]; // mosi
assign uio_out[5] = clk;        // sclk to master

assign uio_oe[3:1] = 3'b0; // csi, csd, mosi
assign uio_oe[5:4] = 2'b1; // miso, sclk

// ...
assign uio_oe[7:6]  = 2'b0;
assign uio_out[7:6] = 3'b0;

// Master //
wire master_en_proc = uio_in[0];
wire master_wr      = (~csi | ~csd) & ~master_en_proc;
assign uio_oe[0] = 1'b0; // proc_en

// Control Signals //
wire      ctrl_pc_sel;
wire      ctrl_pc_en;
wire      ctrl_pc_rst;

wire[2:0] ctrl2alu_unit_sel;
wire      ctrl2alu_op_sel;
wire      ctrl_src_sel;

wire      ctrl2dcache_wen;
wire      ctrl2icache_wen;

wire      ctrl_acc_wen;

wire      ctrl_buff_shen;

control_logic control_logic_0 (
  .clk          (clk),
  .rst          (rst),

  .opcode_in    (icache_data[OPC_W-1:0]),
  .pc_in        (pc                    ),
  .alu_res_in   (alu_res               ),

  .master_en_proc_in (master_en_proc),
  .master_wr_in      (master_wr),

  .pc_sel_out   (ctrl_pc_sel),
  .pc_en_out    (ctrl_pc_en ),
  .pc_rst_out   (ctrl_pc_rst),

  .unit_sel_out (ctrl2alu_unit_sel),
  .op_sel_out   (ctrl2alu_op_sel  ),
  .src_sel_out  (ctrl_src_sel     ),

  .icache_wen_out (ctrl2icache_wen),
  .dcache_wen_out (ctrl2dcache_wen),
  
  .buff_shen_out (ctrl_buff_shen),
  .acc_wen_out   (ctrl_acc_wen  )
);

shift_reg #(
  .SIZE(`DATAPATH_W + 4)
)
shift_reg_0(
  .sclk     (sclk),
  .sdata_in (mosi),
  .en_in    (),

  .data_out (sr_data)
);

cache #(
  .SIZE(`IMEM_SZ)
)
icache(
  .clk      (clk),
  .rst      (rst),

  .data_in  (sr_data[11:4]),
  .addr_in  (sr_data[3:0]),
  .en_in    (ctrl2icache_wen),

  .data_out (icache_data)
);

cache #(
  .SIZE(`DMEM_SZ)
)
dcache(
  .clk      (clk),
  .rst      (rst),

  .data_in  (acc),
  .addr_in  (rs),
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
reg[4:0] seg7In;
always @(*) begin
  case (ui_in[3:0])
    4'hF: seg7In = {1'h1, pc};
    default: seg7In = {1'h1, pc};
  endcase
end

seven_seg seven_seg_0 ( .in(seg7In), .out(uo_out) );

endmodule