# Mini-CPU-DE2-115

# FPGA Processor Core Design Project (DE2-115)

![Intel Quartus](https://img.shields.io/badge/Intel_Quartus_Prime-0071C5?style=for-the-badge&logo=intel&logoColor=white)
![HDL](https://img.shields.io/badge/HDL-Verilog-blue?style=for-the-badge)
![Target](https://img.shields.io/badge/Target-DE2--115%20(Cyclone%20IV)-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

## 📌 Overview

This repository contains the hardware design, implementation, and simulation of a fully functional **Mini-CPU** developed in **Verilog HDL** specifically tailored for the **Terasic/Intel DE2-115 FPGA Development Board (Cyclone IV)**[cite: 1]. The architecture integrates an Arithmetic Logic Unit (ALU)[cite: 1], a virtual RAM Register File of $16 \times 16$ bits (16 internal registers of 16 bits each)[cite: 1, 9], and a controller driver for an **on-board 16x2 Character LCD Display**[cite: 1, 2].

Instructions are manually provided via the 18 physical slide switches (`SW[17:0]`)[cite: 1, 5] and dispatched using push buttons with edge-triggered release detection[cite: 1, 3]. The full instruction cycle—Fetch, Decode, Execute, and Memory Writeback—is reflected live on the LCD display[cite: 2, 3, 5].

---

## ✨ Key Features

- **Instruction Processing:** Hardware decoding for 8 instructions categorized into 4 distinct types (Reg x Reg Arithmetic, Reg x Immediate Arithmetic, Load, and Special Control/Output)[cite: 5, 6, 7].
- **$16 \times 16$ Register File:** Integrated RAM data memory supporting 16 general-purpose 16-bit registers (`R0` through `R15`)[cite: 7, 9].
- **16x2 LCD Visual Interface:** Live display showing the active operation mnemonic (e.g., `ADD`, `LOAD`, `CLEAR`), the destination register in 4-bit binary format `[xxxx]`, and the signed operation result (`+99999` / `-99999`)[cite: 2, 7, 8].
- **Power State Control & Reset:** ON/OFF button logic controlling system power state[cite: 1, 3, 4]. Turning off the system clears all 16 registers to zero and disables the LCD screen[cite: 1, 4].
- **Single-Trigger Execution (Send Button):** Guarantees that instruction processing occurs strictly once per button press-and-release cycle[cite: 1, 3].

---

## 📜 Instruction Set Architecture (ISA) & Opcodes

The CPU processes **18-bit** inputs configured via the board switches (`SW[17:0]`)[cite: 5], mapped according to the 3-bit opcodes below[cite: 5]:

| Instruction | Opcode | Type | Switch Input Format (`SW[17:0]`) | Description |
| :--- | :---: | :---: | :--- | :--- |
| **`LOAD`** | `000`[cite: 5] | Type 3 (Load)[cite: 6] | `[13:11]` Opcode \| `[10:7]` Dest \| `[6]` Sign \| `[5:0]` Imm[cite: 6] | Loads immediate value $Imm$ directly into register $Dest$[cite: 6]. |
| **`ADD`** | `001`[cite: 5] | Type 1 (Reg x Reg)[cite: 5] | `[14:12]` Opcode \| `[11:8]` Dest \| `[7:4]` Src1 \| `[3:0]` Src2[cite: 5] | Adds register values: $Dest = Src1 + Src2$[cite: 5]. |
| **`ADDI`** | `010`[cite: 5] | Type 2 (Reg x Imm)[cite: 5] | `[17:15]` Opcode \| `[14:11]` Dest \| `[10:7]` Src1 \| `[6]` Sign \| `[5:0]` Imm[cite: 6] | Adds immediate value: $Dest = Src1 + Imm$[cite: 5]. |
| **`SUB`** | `011`[cite: 5] | Type 1 (Reg x Reg)[cite: 5] | `[14:12]` Opcode \| `[11:8]` Dest \| `[7:4]` Src1 \| `[3:0]` Src2[cite: 5] | Subtracts register values: $Dest = Src1 - Src2$. |
| **`SUBI`** | `100`[cite: 5] | Type 2 (Reg x Imm)[cite: 5] | `[17:15]` Opcode \| `[14:11]` Dest \| `[10:7]` Src1 \| `[6]` Sign \| `[5:0]` Imm[cite: 6] | Subtracts immediate value: $Dest = Src1 - Imm$[cite: 6]. |
| **`MUL`** | `101`[cite: 5] | Type 2 (Reg x Imm)[cite: 5] | `[17:15]` Opcode \| `[14:11]` Dest \| `[10:7]` Src1 \| `[6]` Sign \| `[5:0]` Imm[cite: 6] | Multiplies register by immediate: $Dest = Src1 \times Imm$[cite: 6]. |
| **`CLEAR`** | `110`[cite: 5] | Special[cite: 6] | `[7:4]` Opcode (`110`)[cite: 7] | Clears all 16 registers in the register file to `0x0000`[cite: 6]. |
| **`DISPLAY`**| `111`[cite: 5] | Special[cite: 6] | `[7:4]` Opcode (`111`) \| `[3:0]` Src1[cite: 7] | Displays the stored value of register $Src1$ on the LCD[cite: 6, 7]. |

---

## 🛠️ Tools & Hardware

| Category | Component / Tool |
| :--- | :--- |
| **EDA Tool** | Intel Quartus Prime (Lite / Standard Edition) |
| **Hardware Target**| Terasic DE2-115 Board (Altera Cyclone IV EP4CE115F29C7)[cite: 1] |
| **Display Peripherals** | On-Board 16x2 Character LCD (HD44780 / Equivalent)[cite: 1, 2] |
| **HDL Language** | Verilog HDL (`.v`) |
| **Programming Tool** | Quartus Programmer via On-Board USB-Blaster |

---

## 📁 Project Structure

```text
.
├── rtl/                        # Hardware description modules
│   ├── module_mini_cpu.v       # Top-level module & CPU finite state machine[cite: 8]
│   ├── module_alu.v            # Arithmetic Logic Unit (ALU)
