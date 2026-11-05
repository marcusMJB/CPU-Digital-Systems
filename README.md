# CPU-Digital-Systems

# FPGA Processor Core Design Project

![Intel Quartus](https://img.shields.io/badge/Intel_Quartus_Prime-0071C5?style=for-the-badge&logo=intel&logoColor=white)
![HDL](https://img.shields.io/badge/HDL-Verilog-blue?style=for-the-badge)
![Target](https://img.shields.io/badge/Target-FPGA_Board-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

## 📌 Overview

This repository contains the hardware design, implementation, and simulation of a fully functional **Processor Core (CPU)** developed in **Verilog HDL**. The architecture includes a custom Datapath, Control Unit, Register File, ALU, and Memory integration. 

The design is synthesized, analyzed, and compiled using **Intel Quartus Prime** and deployed directly onto an **FPGA board** for real-time instruction execution and hardware validation.

> **Note:** Replace this text with specific details about your architecture (e.g., "This project implements a 16-bit Single-Cycle RISC CPU / 32-bit Pipelined MIPS Processor supporting arithmetic, logic, branch, and memory operations").

---

## ✨ Key Features

- **Modular RTL Design:** Structured in pure Verilog HDL, dividing Datapath, Control Unit, and Memory.
- **Instruction Set Architecture (ISA):** Complete hardware decoding for R-Type, I-Type, and J-Type instructions.
- **Register File & ALU Integration:** Multi-register storage paired with an ALU for execution of mathematical and logical operations.
- **On-Board Hardware Verification:** Tested directly on FPGA using switches for manual inputs/clocks, push buttons for reset, and 7-segment displays/LEDs to show PC and Register contents.
- **Simulation & Testbenches:** Module-level and top-level verification using testbenches and GTKWave / ModelSim / Quartus Simulator.

---

## 🛠️ Tools & Hardware

| Category | Component / Tool |
| :--- | :--- |
| **EDA Tool** | Intel Quartus Prime (Lite / Standard Edition) |
| **Simulation Tool** | ModelSim / Questa Intel FPGA / Icarus Verilog |
| **Hardware Target**| FPGA Development Board (e.g., Cyclone IV, Cyclone V DE10-Lite) |
| **HDL Language** | Verilog HDL (`.v`) |
| **Programming** | Quartus Programmer via USB-Blaster |

---

## 📁 Project Structure

```text
.
├── rtl/                    # Top-level and sub-module Verilog files
│   ├── cpu_top.v           # Top-level CPU wrapper
│   ├── datapath.v          # Datapath module linking ALU, PC, and RegFile
│   ├── control_unit.v      # Instruction decoder and control signal generator
│   ├── alu.v               # Arithmetic Logic Unit
│   ├── register_file.v     # CPU internal registers
│   ├── pc.v                # Program Counter register
│   ├── instruction_mem.v   # Instruction Memory (ROM / RAM)
│   └── data_mem.v          # Data Memory (RAM)
├── tb/                     # Verilog testbenches for simulation
│   ├── cpu_tb.v            # Top-level processor testbench
│   └── alu_tb.v            # Individual module testbenches
├── quartus/                # Quartus project files (.qpf, .qsf, output_files)
├── docs/                   # ISA specification, datapath schematics, pinouts
├── tools/                  # Assembler scripts (.py / .sh) to generate hex machine code
└── README.md               # Project documentation
