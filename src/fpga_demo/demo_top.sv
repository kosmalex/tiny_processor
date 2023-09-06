module demo_top (
  input logic clk, rst,

  input logic[15:0] sw,
  output logic[15:0] leds,

  output logic[7:0] s7,
  output logic[7:0] an
);

logic drive;
assign drive = sw[15];

logic[7:0] uo_out;
logic[7:0] ui_in;
logic[7:0] uio_out;
logic[7:0] uio_in;
logic[7:0] uio_oe;

logic display_on;
logic lsB;
logic[3:0] addr_in;

logic [6:0] segments = uo_out[6:0];
logic       msb      = uo_out[7];

logic d_done_out;
logic done_in;
logic rst_n, mosi_out;
logic[1:0] mode_out;

assign rst_n = ~rst;

// Processor
logic p_sclk;
logic p_mosi;
logic p_cs;

assign uio_in[1:0] = mode_out;
assign done_in     = uio_out[2];
assign p_sclk      = uio_out[3];
assign uio_in[4]   = (drive & done_in) ? 1'b0 : mosi_out;
assign p_mosi      = uio_out[5];
assign p_cs        = uio_out[6];
assign p_sync      = uio_out[7];

logic[7:0] s7_n;
assign s7 = ~s7_n;

driver #( .nInstructions(32), .nRegisters(16) )
driver_0 (.clk(clk), .*, .done_out(d_done_out));

tt_um_tiny_processor tt_um_tiny_processor_0 (
  .ui_in   (sw[7:0]), // Dedicated inputs
  .uo_out  (s7_n   ), // Dedicated outputs
  .uio_in  (uio_in ), // IOs: Input path
  .uio_out (uio_out), // IOs: Output path
  .uio_oe  (uio_oe ), // IOs: Enable path (active high: 0=input, 1=output)
  .ena     (1'b1   ), // enable - goes high when design is selected
  .clk     (clk    ), // clock
  .rst_n   (rst_n  )  // not reset
);

assign leds[7:0]  = sw[7:0];
assign leds[8]    = p_sync;
assign leds[15]   = sw[15];
assign leds[14:9] = 6'b0;
assign an         = 8'hFE;

endmodule