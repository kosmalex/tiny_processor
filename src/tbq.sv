`default_nettype none
`timescale 1ns/1ps

module tbq;
  logic [7:0] uo_out;
  logic [7:0] ui_in;
  logic [7:0] uio_out;
  logic [7:0] uio_in;
  logic [7:0] uio_oe;
  logic clk;
  logic rst_n;
  logic ena;

  // wire up the inputs and outputs
  logic[1:0] mode;
  logic      mosi;   

  logic display_on;
  logic lsB;
  logic[3:0] addr_in;

  assign ui_in[0] = display_on;
  assign ui_in[1] = lsB;
  assign ui_in[5:2] = addr_in;

  assign uio_in[1:0] = mode;
  assign uio_in[2]   = mosi;
  
  logic done;
  assign done = uio_out[3];

  logic [6:0] segments = uo_out[6:0];
  logic       lsb      = uo_out[7];

  initial begin
    clk = 0;
    forever #5ns clk = ~clk;
  end

///////////////////////////////////////////////////
  logic[7:0] insts[100];

  initial begin
    RESET();

    MULTIPLY();

    $stop();
  end
///////////////////////////////////////////////////

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
    rst_n = 0;
    mode  = 0;
    mosi  = 0;

    display_on = 0;
    addr_in    = 0;
    lsB        = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
  endtask

  task SPI_i(logic[11:0] data);
    @(posedge clk) begin
      mode  <= #5ns 2'b01;
      mosi <= #5ns data[0]; 
    end

    for (int i = 1; i < 12; i++) begin
      @(posedge clk) begin
        mosi <= data[i]; 
      end
    end

    @(posedge clk) begin
      mode  <= #5ns 2'b00;
    end

    @(posedge done);
  endtask

  task SPI_d(logic[11:0] data);
    @(posedge clk) begin
      mode <= #5ns 2'b10;
      mosi <= #5ns data[0]; 
    end

    for (int i = 1; i < 12; i++) begin
      @(posedge clk) begin
        mosi <= data[i]; 
      end
    end

    @(posedge clk) begin
      mode  <= #5ns 2'b00;
    end

    @(posedge done);
  endtask

  task MULTIPLY();
    $readmemh("../compiler/mul.tx", insts);

    for (int i = 0; i < 16; i++) begin
      $display($time, " Writting: %h", insts[i]);
      SPI_i({insts[i], i[3:0]});
    end

    mode <= 2'b11;
    @(posedge clk);

    @(posedge done) begin
      mode <= 2'b0;
    end

    for (int i = 0; i < 16; i++) begin
      $display($time, " Writting: %h", insts[16 + i]);
      SPI_i({insts[16 + i], i[3:0]});
    end

    mode <= 2'b11;
    @(posedge clk);

    @(posedge done);
  endtask

  task VEC_ADD();
    $readmemh("../compiler/vec_add.tx", insts);

    for (int i = 0; i < 10; i++) begin
      $display($time, " Writting: %h", insts[i]);
      SPI_i({insts[i], i[3:0]});
    end

    mode <= 2'b11;
    @(posedge clk);

    @(posedge done) begin
      mode <= 2'b0;
    end

    for (int i = 0; i < 10; i++) begin
      $display($time, " Writting: %h", insts[10 + i]);
      SPI_i({insts[10 + i], i[3:0]});
    end

    mode <= 2'b11;
    @(posedge clk);

    @(posedge done) begin
      mode <= 2'b0;
    end

    for (int i = 0; i < 15; i++) begin
      $display($time, " Writting: %h", insts[20 + i]);
      SPI_i({insts[20 + i], i[3:0]});
    end

    mode <= 2'b11;
    @(posedge clk);

    @(posedge done);
  endtask
endmodule
