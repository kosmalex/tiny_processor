`timescale 1ns/1ps

module tb;

logic clk, rst;

initial begin
  clk = 0;
  forever #5ns clk = ~clk;
end

logic [7:0] uo_out;
logic [7:0] ui_in;
logic [7:0] uio_out;
logic [7:0] uio_in;
logic [7:0] uio_oe;

logic display_on;
logic lsB;
logic[3:0] addr_in;

logic [6:0] segments = uo_out[6:0];
logic       lsb      = uo_out[7];

logic drive, done_in;
logic sclk_out, rst_n_out, mosi_out;
logic[1:0] mode_out;

assign done_in = uio_out[3];
assign ui_in[0] = display_on;
assign ui_in[1] = lsB;
assign ui_in[5:2] = addr_in;

assign uio_in[1:0] = mode_out;
assign uio_in[2]   = mosi_out;


driver dut (.*);

tt_um_tiny_processor tt_um_tiny_processor (
  .ui_in   (ui_in),    // Dedicated inputs
  .uo_out  (uo_out),   // Dedicated outputs
  .uio_in  (uio_in),   // IOs: Input path
  .uio_out (uio_out),  // IOs: Output path
  .uio_oe  (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
  .ena     (1'b1),     // enable - goes high when design is selected
  .clk     (sclk_out), // clock
  .rst_n   (rst_n_out) // not reset
);

initial $readmemh("../../compiler/fact.tx", dut.mem);

initial begin
  RESET();

  drive <= 1'b1;
  repeat (100) @(posedge clk);

  $stop;
end

task RESET();
  rst <= 1'b1;
  drive <= 1'b0;
  repeat(10) @(posedge clk);
  rst <= 1'b0;
  repeat( 5) @(posedge clk);
endtask

endmodule