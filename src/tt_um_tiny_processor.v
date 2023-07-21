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

module control_logic (
  input wire[3:0] opcode_in,
  input wire[3:0] pc_in,
  input wire[7:0] alu_res_in,
  
  output wire      pc_sel_out,
  output wire      pc_en_out,

  output wire[2:0] unit_sel_out,
  output wire      op_sel_out,
  output wire      src_sel_out,
  output wire      wen_out,

  output wire      wacc_en_out
);

// Check if `bnez` branch is taken
wire is_branch   = &opcode_in;
wire is_not_zero = |alu_res_in;
wire is_taken    = is_branch & is_not_zero;

assign pc_sel_out = is_taken;

/** If the last instruction is not a branch or is a not taken branch -->
    the programm has terminated --> freeze `pc`.
 */
assign pc_en_out  = ~( &pc_in & (~is_branch | ~is_taken) );

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
assign wen_out = &opcode_in[2:0];

// When storing don't write accumulator register
assign wacc_en_out = ~wen_out;

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

// Global //
reg[`INST_W-1:0]     imem[0:`IMEM_SZ-1];
reg[`DATAPATH_W-1:0] dmem[0:`DMEM_SZ-1];

wire rst = ~rst_n;

// Fetch-Decode //
reg [PC_W-1:0]        pc;
wire[PC_W-1:0]        jmp;
wire[`INST_W-1:0]     inst;
wire[RID_W-1:0]       rs;
wire[3:0]             imm;

// ALU //
wire[`DATAPATH_W-1:0] src;
reg[`DATAPATH_W-1:0]  acc;
reg[`DATAPATH_W-1:0]  alu_res;
reg[`DATAPATH_W-1:0]  op_data;

// Control Signals //
reg      ctrl_pc_sel;
reg      ctrl_pc_en;

reg[2:0] ctrl2alu_unit_sel;
reg      ctrl2alu_op_sel;
reg      ctrl_src_sel;

reg      ctrl_wen;

reg      ctrl_wacc_en;

control_logic control_logic_0 (
  .opcode_in    (inst[OPC_W-1:0]),
  .pc_in        (pc),
  .alu_res_in   (alu_res),

  .pc_sel_out   (ctrl_pc_sel),
  .pc_en_out    (ctrl_pc_en),

  .unit_sel_out (ctrl2alu_unit_sel),
  .op_sel_out   (ctrl2alu_op_sel),
  .src_sel_out  (ctrl_src_sel),
  .wen_out      (ctrl_wen),

  .wacc_en_out  (ctrl_wacc_en)
);

// No bidirectional IO
assign uio_oe  = 8'h0;
assign uio_out = 8'h0;

always @(posedge clk) begin
  if ( rst ) begin
    imem[0 ] <= 8'h1B;
    imem[1 ] <= 8'h17;
    imem[2 ] <= 8'h1B;
    imem[3 ] <= 8'h37;
    imem[4 ] <= 8'hFB;
    imem[5 ] <= 8'h07;
    imem[6 ] <= 8'h11;
    imem[7 ] <= 8'h20;
    imem[8 ] <= 8'h27;
    imem[9 ] <= 8'h03;
    imem[10] <= 8'h36;
    imem[11] <= 8'h07;
    imem[12] <= 8'h6F;
    imem[13] <= 8'h00;
    imem[14] <= 8'h00;
    imem[15] <= 8'h00;
  end else begin
    //Nothing for now...
  end
end

assign inst = imem[pc];
assign jmp  = inst[7:4];
assign imm  = inst[7:4];
assign rs   = inst[7:4];

// Early branch detect
always @(posedge clk) begin
  if ( rst ) begin
    pc <= 0;
  end else if (ctrl_pc_en) begin
    pc <= ctrl_pc_sel ? jmp : pc+1;
  end
end

// Execute-Writeback stage //
wire[`DATAPATH_W-1:0] sext_imm = {{4{imm[3]}}, imm};

assign src = ctrl_src_sel ? sext_imm : dmem[rs];

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
  end else if (ctrl_wacc_en) begin
    acc <= alu_res;
  end
end

always @(posedge clk) begin
  if ( rst ) begin
    dmem[0] <= 8'h0;
    dmem[1] <= 8'h0;
    dmem[2] <= 8'h0;
    dmem[3] <= 8'h0;
    dmem[4] <= 8'h0;
    dmem[5] <= 8'h0;
    dmem[6] <= 8'h0;
    dmem[7] <= 8'h0;
    dmem[8] <= 8'h0;
    dmem[9] <= 8'h0;
    dmem[10] <= 8'h0;
    dmem[11] <= 8'h0;
    dmem[12] <= 8'h0;
    dmem[13] <= 8'h0;
    dmem[14] <= 8'h0;
  end else if ( ctrl_wen ) begin
    dmem[rs] <= acc;
  end
end

reg[4:0] seg7In;
always @(*) begin
  case (ui_in[3:0])
    4'h0: seg7In = ui_in[4] ? {1'h1, dmem[0] [7:4]} : {1'h0, dmem[0] [3:0]};
    4'h1: seg7In = ui_in[4] ? {1'h1, dmem[1] [7:4]} : {1'h0, dmem[1] [3:0]};
    4'h2: seg7In = ui_in[4] ? {1'h1, dmem[2] [7:4]} : {1'h0, dmem[2] [3:0]};
    4'h3: seg7In = ui_in[4] ? {1'h1, dmem[3] [7:4]} : {1'h0, dmem[3] [3:0]};
    4'h4: seg7In = ui_in[4] ? {1'h1, dmem[4] [7:4]} : {1'h0, dmem[4] [3:0]};
    4'h5: seg7In = ui_in[4] ? {1'h1, dmem[5] [7:4]} : {1'h0, dmem[5] [3:0]};
    4'h6: seg7In = ui_in[4] ? {1'h1, dmem[6] [7:4]} : {1'h0, dmem[6] [3:0]};
    4'h7: seg7In = ui_in[4] ? {1'h1, dmem[7] [7:4]} : {1'h0, dmem[7] [3:0]};
    4'h8: seg7In = ui_in[4] ? {1'h1, dmem[8] [7:4]} : {1'h0, dmem[8] [3:0]};
    4'h9: seg7In = ui_in[4] ? {1'h1, dmem[9] [7:4]} : {1'h0, dmem[9] [3:0]};
    4'hA: seg7In = ui_in[4] ? {1'h1, dmem[10][7:4]} : {1'h0, dmem[10][3:0]};
    4'hB: seg7In = ui_in[4] ? {1'h1, dmem[11][7:4]} : {1'h0, dmem[11][3:0]};
    4'hC: seg7In = ui_in[4] ? {1'h1, dmem[12][7:4]} : {1'h0, dmem[12][3:0]};
    4'hD: seg7In = ui_in[4] ? {1'h1, dmem[13][7:4]} : {1'h0, dmem[13][3:0]};
    4'hE: seg7In = ui_in[4] ? {1'h1, dmem[14][7:4]} : {1'h0, dmem[14][3:0]};
    4'hF: seg7In = {1'h1, pc};

    default: seg7In = {1'h1, pc};
  endcase
end

seven_seg seven_seg_0 ( .in(seg7In), .out(uo_out) );

endmodule