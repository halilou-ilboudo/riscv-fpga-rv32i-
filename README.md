\# RV32I RISC-V Processor on FPGA (Arty A7)



Academic project: design and implementation of a minimal 32-bit RV32I RISC-V CPU in VHDL, running on Digilent Arty A7 (Artix-7).

Includes a UART bootloader to program instruction memory, and MMIO peripherals (GPIO, timer, UART).



\## Features

\- RV32I single-cycle CPU (PC, ALU, RegFile, Control Unit)

\- UART bootloader to load program binaries into Instruction Memory

\- MMIO: GPIO, Timer, UART TX

\- Tested in simulation (Vivado/XSim) and on hardware (Arty A7)



\## Toolchain

\- riscv64-unknown-elf-gcc (RV32I)

\- Vivado 2021.2



\## How to run

1\. Generate binary: `make`

2\. Send `<program>.bin` over UART + terminator `FF FF FF FF`

3\. Observe LEDs / UART output



\## Author

Halilou Ilboudo

