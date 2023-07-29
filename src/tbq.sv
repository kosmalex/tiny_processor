`default_nettype none
`timescale 1ns/1ps

module tbq;
  wire [7:0] uo_out;
  wire [7:0] ui_in;
  wire [7:0] uio_out;
  wire [7:0] uio_in;
  wire [7:0] uio_oe;
  wire clk;
  wire rst_n;
  wire ena;

  // wire up the inputs and outputs
  wire proc_en;
  wire csi;    
  wire csd;    
  wire mosi;   

  wire display_on;
  wire lsB;
  wire[3:0] addr_in;

  assign ui_in[0] = display_on;
  assign ui_in[1] = lsB;
  assign ui_in[5:2] = addr_in;

  assign uio_in[0] = proc_en;
  assign uio_in[1] = csi; 
  assign uio_in[2] = csd; 
  assign uio_in[3] = mosi;
  
  wire done = uio_out[5];

  wire [6:0] segments = uo_out[6:0];
  wire       lsb      = uo_out[7];

  initial begin
    clk = 0;
    forever #5ns clk = ~clk;
  end

  initial begin
    RESET();
  
    $stop();
  end

  tt_um_tiny_processor tt_um_tiny_processor (
    .ui_in      (ui_in),    // Dedicated inputs
    .uo_out     (uo_out),   // Dedicated outputs
    .uio_in     (uio_in),   // IOs: Input path
    .uio_out    (uio_out),  // IOs: Output path
    .uio_oe     (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
    .ena        (ena),      // enable - goes high when design is selected
    .clk        (clk),      // clock
    .rst_n      (rst_n)     // not reset
  );

  task RESET();
    rst_n   = 1;
    proc_en = 0;
    csi     = 1;
    csd     = 1;
    mosi    = 0;

    display_on = 0;
    addr_in    = 0;
    lsB        = 0;
    repeat(10) @(posedge clk);
    rst_n = 0;
    @(posedge clk);

  endtask

endmodule
