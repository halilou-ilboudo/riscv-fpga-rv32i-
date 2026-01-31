# RV32I RISC-V Processor on FPGA

This project presents the design and implementation of a **32-bit RISC-V (RV32I) processor** described in **VHDL** and deployed on an **FPGA (Digilent Arty A7 – Artix-7)**.

The processor follows a **single-cycle architecture** and supports memory-mapped peripherals accessed through MMIO.

---

## 🧠 Processor Architecture

The processor includes:
- Program Counter (PC)
- Instruction Memory
- Register File (32 registers × 32 bits)
- Arithmetic Logic Unit (ALU)
- Control Unit
- Data Memory
- Memory-Mapped I/O (MMIO)

Supported ISA:
- **RISC-V RV32I (base integer instruction set)**

---

## 🧩 Memory Organization

| Component | Type | Size |
|---------|------|------|
| Instruction Memory | BRAM | 1024 × 32-bit words |
| Data Memory | BRAM | 1024 × 32-bit words |
| Register File | Flip-flops | 32 registers × 32 bits |

Instruction memory is programmed through a **UART bootloader**.

---

## 🔌 Peripherals (MMIO)

The processor interacts with peripherals using Memory-Mapped I/O:
- GPIO (LEDs, inputs)
- UART (TX)
- Timer

Each peripheral is mapped to a dedicated address range.

---

## 💻 Software Toolchain

The software is compiled using:
- **riscv64-unknown-elf-gcc**

Software components include:
- Startup assembly (`start.s`)
- Linker script (`linker.ld`)
- C programs (GPIO, UART, timer tests)
- Python script to send binaries via UART

---

## 🧪 Validation

The design was validated through:
- Simulation using **Vivado / XSim**
- Synthesis and implementation on FPGA
- Real hardware tests (LED blinking, UART output)

---

## 📁 Project Structure
project/
├── hw/        # VHDL source files (processor + peripherals)
└── sw/        # Software (C, ASM, Makefile, linker)

---

## 🛠 Technologies

- VHDL
- RISC-V
- FPGA (Xilinx Artix-7)
- Vivado
- UART
- MMIO
- Embedded Systems

---

## 📜 License

This project is released under the **MIT License**.



\## Author

Halilou Ilboudo

