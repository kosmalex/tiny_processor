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

// Global //
reg[`INST_W-1:0]     imem[0:`IMEM_SZ-1];
reg[`DATAPATH_W-1:0] dmem[0:`DMEM_SZ-1];

wire rst = ~rst_n;

// No bidirectional IO
assign uio_oe  = 8'h0;
assign uio_out = 8'h0;

// Fetch-Decode stage //
localparam PC_W = `CLOG2(`IMEM_SZ);

reg[PC_W-1:0] pc;

always @(posedge clk) begin
  if ( rst ) begin
    imem[0 ] <= 8'h59;
    imem[1 ] <= 8'h0F;
    imem[2 ] <= 8'h19;
    imem[3 ] <= 8'h1F;
    imem[4 ] <= 8'h1E;
    imem[5 ] <= 8'h05;
    imem[6 ] <= 8'h1F;
    imem[7 ] <= 8'h0E;
    imem[8 ] <= 8'hF8;
    imem[9 ] <= 8'h0F;
    imem[10] <= 8'h43;
    imem[11] <= 8'h00;
    imem[12] <= 8'h00;
    imem[13] <= 8'h00;
    imem[14] <= 8'h00;
    imem[15] <= 8'h00;
  end else begin
    //Nothing for now...
  end
end

wire[`INST_W-1:0] inst = imem[pc];

wire[3:0] opcode = inst[3:0];
wire[3:0] jmp    = inst[7:4];
wire[3:0] rs     = inst[7:4];
wire[3:0] imm    = inst[7:4];

// Forward accumulator register
wire[`DATAPATH_W-1:0] fwd_alu_res;

// Early branch detect
always @(posedge clk) begin
  if ( rst ) begin
    pc <= 0;
  end else begin
    if ( opcode == 4'h3 ) begin
        pc <= ( fwd_alu_res != 0 ) ? jmp : pc+1;
    end else if (pc != 4'hF) begin
      pc <= pc + 1;
    end
  end
end

// // IR //
// reg[3:0] ir_opcode, ir_rs, ir_imm;
// always @(posedge clk) begin
//   if ( rst ) begin
//     ir_opcode <= 0;
//     ir_rs     <= 0;
//     ir_imm    <= 0;
//   end else begin
//     ir_opcode <= opcode;
//     ir_rs     <= rs;
//     ir_imm    <= imm;
//   end
// end

// // Execute-Writeback stage //
// reg[`DATAPATH_W-1:0] acc;

// wire[`DATAPATH_W-1:0] op_data  = dmem[ir_rs];
// wire[`DATAPATH_W-1:0] sext_imm = {{4{ir_imm[3]}}, ir_imm};

// Execute-Writeback stage //
reg[`DATAPATH_W-1:0] acc;

wire[`DATAPATH_W-1:0] op_data  = dmem[rs];
wire[`DATAPATH_W-1:0] sext_imm = {{4{imm[3]}}, imm};

// ALU
reg[`DATAPATH_W-1:0] alu_res;
always @(*) begin
  case (opcode)
    4'h0: alu_res = op_data + acc;        //ADD
    4'h1: alu_res = acc + ~(op_data) + 1; //SUB
    4'h2: alu_res = acc << op_data[2:0];  //SLL
    4'h4: alu_res = acc >> op_data[2:0];  //SRL
    // 4'h5: alu_res = op_data * acc;        //MUL
    4'h6: alu_res = ~(op_data & acc);     //NAND
    4'h7: alu_res = op_data ^ acc;        //XOR
    4'h8: alu_res = sext_imm + acc;       //ADDI
    4'h9: alu_res = sext_imm;             //LI
    4'hA: alu_res = acc << sext_imm[2:0]; //SLLI
    
    4'hD: alu_res = 0;                    //RST
    4'hE: alu_res = op_data;              //LOAD ACC or LA
    4'hF: alu_res = acc;                  //STORE ACC or SA

    default: alu_res = acc;               // NOOP
  endcase
end

// Forward ALU res to Fetch stage
assign fwd_alu_res = alu_res;

always @(posedge clk) begin
  if ( rst ) begin
    acc <= 0;
  end else begin
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
  end else if ( opcode == 4'hF ) begin
    dmem[rs] <= alu_res;
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