module demo_top (
  input logic clk, rst,

  input logic[15:0] sw,
  output logic[7:0] leds,

  output logic[7:0] s7,
  output logic[7:0] an
);

logic drive;
assign drive = sw[15];

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

logic done_in;
logic sclk_out, rst_n_out, mosi_out;
logic[1:0] mode_out;

assign done_in     = uio_out[3];
assign uio_in[1:0] = mode_out;
assign uio_in[2]   = mosi_out;

logic[7:0] s7_n;
assign s7 = ~s7_n;

driver driver_0 (.*);

tt_um_tiny_processor tt_um_tiny_processor_0 (
  .ui_in   (sw[7:0]),  // Dedicated inputs
  .uo_out  (s7_n),     // Dedicated outputs
  .uio_in  (uio_in),   // IOs: Input path
  .uio_out (uio_out),  // IOs: Output path
  .uio_oe  (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
  .ena     (1'b1),     // enable - goes high when design is selected
  .clk     (sclk_out), // clock
  .rst_n   (rst_n_out) // not reset
);

assign leds = sw;
assign an   = 8'hFE;
endmodule