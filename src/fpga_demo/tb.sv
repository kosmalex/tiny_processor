`timescale 1ns/1ps

module tb;

logic clk, pclk, rst;

initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

initial begin
  pclk = 0;
  forever #10ns pclk = ~pclk;
end

logic [7:0] uo_out;
logic [7:0] ui_in;
logic [7:0] uio_out;
logic [7:0] uio_in;
logic [7:0] uio_oe;

logic miso, mosi, cs;
logic display_on;
logic msb;
logic view_sel;
logic anim_en;

logic[3:0] addr_in;

logic [6:0] segments = uo_out[6:0];
logic       lsb      = uo_out[7];

logic sel_dev;
logic done_drive;
logic drive, done_in;
logic mosi_out;
logic[1:0] mode_out;

logic rst_n;

assign done_in    = uio_out[2];
assign ui_in[0]   = display_on;
assign ui_in[1]   = msb;
assign ui_in[5:2] = addr_in;
assign ui_in[6]   = view_sel;
assign ui_in[7]   = anim_en;

assign uio_in[1:0] = mode_out;
assign uio_in[4]   = sel_dev ? miso : mosi_out;
assign mosi        = uio_out[5];
assign cs          = uio_out[6];

driver #( .nInstructions(16), .nRegisters(16) )
dut     ( .clk(clk), .*, .done_out(d_done_out));

device device_0 (.*);

tt_um_tiny_processor tt_um_tiny_processor (
  .ui_in   (ui_in),    // Dedicated inputs
  .uo_out  (uo_out),   // Dedicated outputs
  .uio_in  (uio_in),   // IOs: Input path
  .uio_out (uio_out),  // IOs: Output path
  .uio_oe  (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
  .ena     (1'b1),     // enable - goes high when design is selected
  .clk     (clk),      // clock
  .rst_n   (rst_n)     // not reset
);

initial begin
  RESET();

  drive <= 1'b1;
  @(posedge clk);

  @(mode_out == 2'b11) begin
    sel_dev <= 1'b1;
  end

  $stop;
end

task RESET();
  rst        <= 1'b1;
  rst_n      <= 1'b0;
  drive      <= 1'b0;
  sel_dev    <= 1'b0;
  anim_en    <= 1'b1;
  display_on <= 1'b0;
  addr_in    <= 4'b0;
  view_sel   <= 1'b0;
  msb        <= 1'b0;
  repeat(10) @(posedge clk);
  rst <= 1'b0;
  repeat(10) @(posedge clk);
  rst_n <= 1'b1;
endtask

endmodule