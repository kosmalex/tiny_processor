![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/wokwi_test/badge.svg)

# Tiny Processor

The readme file is split into two sections a software part and a hardware part. In the first section we describe the ISA, the programming model and the compiler script that was used to generate the executable files. In the second part we describe the harware components of the *Tiny Processor* design.

## Software

### ISA

The below image shows the processor's ISA.

<p align=center> <img src="figs/TP-ISA.png" alt="figs/TP-ISA.png" width="500"/> </p>

The first column contains the alias of the instruction that is used in the assembly. The second column contains its action, and finally the third, its opcode. The opcode field is comprised of the first 4 bits of the instruction.

<p align=center> <img src="figs/TP-Inst.png" alt="figs/TP-Inst.png" width="400"/> </p>

The table below shows some examples, of the instructions' encoding.

| Instruction | Encoding | Action |
| :-----------: | :-----------: | :-----------: |
| addi -1 | 0xF8 | $acc \leftarrow acc + (-1)$ |
| la x3   | 0x33 | $acc \leftarrow x3$ |
| add x2  | 0x20 | $acc \leftarrow acc + x2$ |
| srl x10 | 0xA6 | $acc \leftarrow acc >> x10[2:0]$ |

### Programming model

#### Register File or Data memory

The processor contains in total 16 registers (Data memory capacity), withought taking into account the program counter and the accumulator registers. The first 15 registers are 8-bits wide while the last is a single bit wide register (a pseudo-register). The registers are divided into 5 groups;

- **GPRs ($x0-x8$)**: These are simple general purpose registers. They store and provide intermediate results or data while the programm is being executed. The GPR registers can be updated w/ the sa instruction (store accumulator).
- **Animation register ($x9$)**: This group contains a single register and it can also be used as a GPR register. It is additionally used to feed the 7-segment display when the animation switch is on.
- **Frame counter registers ($x10-x13$)**: These registers can also be used as GPR registers. Combined (LSR: $x10$) they form a 32-bit unsigned integer value that is used to initialize the frame counter's count, when it is reset.
- **SPI register ($x14$)**: This register is used as a buffer that stores the data that is about to be sent or received from the processor via the SPI interface. For the programmer it is a read-only register.
- **FC sync register ($x15$)**: This is a single bit pseudo-register (it's value is a result of comparing a register with the value 1), that indicates the start of a new frame. This is also a read-only register.

<p align=center> <img src="figs/TP-PM.png" alt="figs/TP-PM.png" width="500"/> </p>

#### Accumulator register

Because the 8-bit width of an instruction allows only for a single 4-bit operand (provided that the opcode is 4-bits), we added an accumulator register.
The accumulator register is an extra 8-bit register used as source and destination register of any arithmetic instruction, as was shown in the ISA image above. An example sequence of instructions to add registers $x5$, $x11$, store the result to register $x0$, and then output the result to an external SPI device would be;

| Instruction | Action |
| :-----------: | :-----------: |
| la  x5 | $acc \leftarrow x5$ |
| add x6 | $acc \leftarrow acc + x6$ |
| sa  x0 | $x0  \leftarrow acc$ |
| spiw x0| $x0  \rightarrow spi\ write$ |

## Compiler

To ease the task of writting programs for the processor, we developed a Python compiler script, located in the `compiler` directory. The script takes as input a .tp file and a format field (`-f` flag; hex (default), bin, dec), and outputs an executable .mem file. Below we demonstrate step-by-step how to create a executable that animates the seven segment display in a circular pattern.

### Go to the compiler directory
```
$ cd <path-to-git-dir>/compiler
```
### Create a .tp file

```
$ vi s7.tp
```

File contents:

```
main:
  la x15
  bnez skip
    la x1
    and x9
    bnez to_init
      la x9
      slli 1
      j skip_rest
    to_init:
      li 1
    skip_rest:
      sa x9
  skip:
j main
```

### Save and compile

Manually:

```
$ python c.py s7.tp -f hex
```

Using bash script:

```
$ ./c.sh
$ File name: s7.tp
$ Format: hex
```

### Create a dummy.mem file

```
$ vi dummy.mem
```

File contents:

```
1
80
0
0
0
0
0
0
0
1
10
0
0
0
0
0
```

#### Note
Only register $x0-x13$ can be initialized w/ the .mem file. The last 2 registers are read-only registers.

### Use of .mem files 

The s7.mem file can be used to initialize the `imem` variable of the driver. Simply insert the file path of the generated .mem file in the corresponding **$readmemh** macro located in the driver.sv module.

```
logic[7:0] imem[16];
logic[7:0] dmem[16];

initial $readmemh("<path>/s7.mem   ", imem);
initial $readmemh("<path>/dummy.mem", dmem);
```

The `dummy.mem` file is an initialization file for the registers;
  - $x0 \leftarrow 8'h01$
  - $x1 \leftarrow 8'h80$
  - $x9 \leftarrow 8'h01$
  - $x10 \leftarrow 8'h10$
  - $other \leftarrow 8'h00$

## Hardware

### IO

Below is a schematic that shows all the inputs and outputs the processor design has.

<p align=center> <img src="figs/TP-IO.png" alt="figs/TP-IO.png" width="800"/> </p>

#### Switches ( ui_in[7:0] )
- **SW[0]**: This switches the display on/off. When the display is off the 7-segment display freezes in the zero value. When it is on the value of SW[5:2] is fed as an address to both memories of the processor.
- **SW[1]**: When this switch is on, bits[7:4] of a byte are shown, and when its off, bits[3:0] are shown.
- **SW[5:2]**: These provide the register's address when SW[0] is on. All registers that can be used as a GPR register can be displayed.
- **SW[6]**: When this switch is turned on data from the instruction memory is displayed. When it's off data from the register file is shown.
- **SW[7]**: This enables the animation of the 7-segment display. When it is turned on the 7-segment display is directly fed by the animation register ($x9$).

#### Outputs ( uo_out[7:0] )

These are directly connected to each segment of the 7-segment display

#### Bidirectional IO ( uio_{in, out}[7:0] )
- **ctrl[1:0] (I)**: These are the control signals that driver uses to initialize processor and tell it to begin execution. The intial value should always be `2'b00`, this means *do nothing*. The driver sends data to the processor in forms of a packet. A packet has 12-bits of data; The data itself (8-bits) and its destination address (4-bits). When the driver wants to write the instruction memory of the processor he sets the control signal to `2'b10` and sends a single packet of data to the processor. When the transaction has completed, the driver stalls for a couple of cycles and procedes to send the next packet. Once all packets for the instruction memory have been sent, the driver switches the control signal to `2'b01` and follows the same procedure to initialize the register file of the processor. 
- **done (O)**: This signal is used to indicate that the processor is in its idle state (does nothing).
- **SPI IO (IO)**: The next 4 IOs belong to the SPI interface.
- **sync (O)**: This last BIO is used to output the value of the $x15$ register. 

### Datapath

Tiny processor is a single-cycle processor with an 8-bit architecture. Its uarchitecture schematic is shown below.

<p align=center> <img src="figs/TP-uARCH.png" alt="figs/TP-uARCH.png" width="1000"/> </p>

#### Program counter

The program counter can have 4 different future values;

  1. `0` if the global reset is enabled
  2. `PC + 1` during sequential execution
  3. `PC` if a stall is present due to spi io operation
  4. `jmp` This is a destination address, in case of a branch instruction

#### IMEM

The IMEM storage can have 3 different sources of register index addresses;

  1. `sw_addr` This address is used to index IMEM when the first switch is enabled
  2. `PC` The program counter value is used during normal execution
  3. `spi_addr` This address is used only when the driver initializes IMEM

(1) and (3) stay the same for DMEM, while (2) instead of the `PC`, `rs` is used.

When the driver module initializes the processor both memories have as input data the `spi_data`. During normal execution instructions' memory is not writable, while the input data to DMEM is the value of the accumulator register.

The schematic of the memory modules is shown below.

<p align=center> <img src="figs/TP-MEM.png" alt="figs/TP-MEM.png" width="500"/> </p>

The DMEM module broadcasts register $x9$ through the `anim_reg` output and registers $x10-x13$ through `frame_cntr_data` output. IMEM does not use these output signals and outputs a zero value.

Below is the mapping between the signals in the **DATAPATH** image and the **MEM** image.

| Datapath | IMEM | DMEM |
| :------: | :------: | :------: |
|inst | data | - |
|rs_data | - | data |
|x9 | - | anim_reg |
|{x13, x12, x11, x10} | - | frame_cntr_data |

#### ALU

The first operand and destination of the ALU-unit is always the accumulator register. The second can alternate between;
  1. `sext imm` This is a 8-bit sign extented immediate encoded in the instruction
  2. `fc_data` This is a single bit value from the frame counter module that indicates the transition between frames
  3. It is zero-extented to 8 bits
  4. `rs_data` This is a value from the register file. It is used when an instruction indexes registers $x0-x13$.
  5. `spi_data` When an instruction indexes the SPI register ($x14$) this operand is chosen

### Frame counter

The input data to the frame counter module is the combination of registers $x10-x11$, that form a 32-bit value. The output single bit value is the so called pseudo register ($x15$). It is enabled (negative enable) at the transition between frames. The diagram of the module is shown in the image below.

<p align=center> <img src="figs/TP-FC.png" alt="figs/TP-FC.png" width="500"/> </p>

The global reset signal `rst`, sets the counter to the 0 value. During normal execution if the signal `ctrl_rst` is enabled the counter is reset to the 32-bit `data` input. Otherwise it decreases by one each clock cycle. When it reaches the 0 value it stays there until it is reset by the control logic through the `ctrl_rst` signal. The output `sig` signal is 0 only when the counter reaches 0.

Below is the mapping between the signals in the **DATAPATH** image and the **FRAME COUNTER** image.

| Datapath | Frame counter |
| :------: | :------: |
|data | {x13, x12, x11, x10} |
|fc_data | sig |

### SPI interface

The schematic of the module is shown below.

<p align=center> <img src="figs/TP-SPI.png" alt="figs/TP-SPI.png" width="1000"/> </p>

Below is the mapping between the signals in the **DATAPATH** image and the **SPI INTERFACE** image.

| Datapath | SPI Interface |
| :------: | :------: |
|spi_addr | addr |
|spi_data | data |
|alu_res | data |

The three main components of the SPI module are the FSM, the counter `NB` that indicates how many bytes have been received or sent, the shift register that buffers the data that are about to be sent or that being received and the phase-shift (`PS`) single bit register.

#### FSM

The finite state machine of the SPI module is pretty simple. When the module receives an incoming request (`send` | `read`) the FSM transitions to `BUSY` state. While in this state it enables the datapath to send or receive data based on the which signal (`send` or `read`) was active. When the transaction is completed (`all_bits_received`) it returns to its `IDLE` state.

#### Number of Bytes counter or NB

The `NB` counter is a 4-bit counter and has 4 possible future values;

  1. `4'd12`: This is the size in bits of a single packet (8-bit data and 4-bit address). The `NB` counter is reset to this value only when the driver module initializes the processor.
  2. `4'd8`: During normal execution the processor sends or receives via SPI a single byte, so the counter is reset to this value.
  3. `NB - 1`: While the transaction through SPI is not yet complete the counter decrements by 1, to count the number of bytes sent or received.
  4. `NB`: When one of the above is not true the counter does nothing.

Once the counter's value reaches 1, it indicates that all bits have been received and so sets the `all_bits_received` signal.

#### Shift register

The shift register stores the data that is about to be sent or received via SPI protocol. When the request is a `read` or when the driver module initializes the processor the each bit received is shifted into the shift register from its `sdata` input. All bits of the shift register are read in parallel (`buffer`). When the processor requests a write to an external device a GPR register is written to the shift register via its `data` input. It is then sent bit by bit thtough the `mosi` IO of the module. The shift register alias is $x14$.

#### Phase shift register

The phase shift register was used to keep the mosi signal stable near the positive edges of the serial clock, to ensure that sent bits are sampled correctly. This register samples values at the negative edge of the input clock.

### 7-seg driver

The diagram for the 7-segment driver is shown below.

<p align=center> <img src="figs/TP-7-seg.png" alt="figs/TP-7-seg.png" width="500"/> </p>

The combinational logic cluster handles the convertion of the 5-bit input `value` to the corresponding 8-bit 7-segment signal pattern. If the animation is enabled (SW[7] is on) the `bit_array` input is broadcast to the 7-segment display through the `out` IO. If the animation is disabled, the signal pattern is broadcast.
