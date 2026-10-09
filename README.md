# SPI Flash Behavioral RTL Model

A behavioral RTL implementation of an SPI Flash memory device using **Verilog HDL**, with a self-checking testbench and simulation-based verification in ModelSim.

This project was developed as part of an electronics engineering assignment to implement an SPI slave interface, support Flash memory commands, and verify the design through simulation.

## Overview

The project models the command behavior of a Winbond W25Q64-style SPI Flash device. It implements SPI communication, status-register handling, memory programming, read operations, erase operations, and JEDEC identification.

For simulation simplicity, the physical Flash memory is represented by a **64 KB behavioral memory array** rather than the full device capacity. The SPI interface accepts 24-bit addresses, while memory access uses the lower 16 bits.

## Features

- SPI slave interface using Mode 0 timing
- Serial data reception through MOSI
- Serial data transmission through MISO
- Command decoding using named Verilog parameters
- Write Enable Latch (WEL) and BUSY status handling
- Behavioral Flash memory initialized to `0xFF`
- NOR Flash programming behavior: bits can change from `1` to `0` during programming
- Sector and block erase operations
- JEDEC ID response
- Self-checking testbench with pass/fail reporting
- Simulation-based verification using ModelSim

## Supported Commands

| Command | Opcode | Description |
|---|---|---|
| Write Enable | `06h` | Sets the Write Enable Latch |
| Write Disable | `04h` | Clears the Write Enable Latch |
| Read Status Register | `05h` | Returns the WEL and BUSY status bits |
| Read Data | `03h` | Reads data from the modeled memory |
| Page Program | `02h` | Programs data into memory when write-enabled |
| Sector Erase | `20h` | Erases a 4 KB sector |
| 32 KB Block Erase | `52h` | Erases a 32 KB block |
| 64 KB Block Erase | `D8h` | Erases the complete 64 KB modeled memory |
| Chip Erase | `C7h` | Erases the complete 64 KB modeled memory |
| Read JEDEC ID | `9Fh` | Returns the ID bytes `EFh`, `40h`, `17h` |

## SPI Interface

The model uses four standard SPI signals:

| Signal | Direction | Description |
|---|---|---|
| `cs` | Input | Active-low chip select |
| `sclk` | Input | SPI serial clock |
| `mosi` | Input | Master Out, Slave In |
| `miso` | Output | Master In, Slave Out |

### SPI Mode

The implementation follows **SPI Mode 0**:

- Clock polarity (`CPOL`) = `0`
- Clock phase (`CPHA`) = `0`
- MOSI data is sampled on the rising edge of SCLK.
- MISO data is updated on the falling edge of SCLK.
- Communication is selected while CS is low.

## Design Architecture

The RTL is organized into three main functional sections.

### 1. SPI Receive and Command Processing

The receive logic captures serial input bits, assembles bytes, decodes command opcodes, and controls the state machine.

### 2. Flash Memory Operations

The behavioral memory supports reading, programming, and erase operations. Programming follows NOR Flash behavior by applying a bitwise AND between the existing memory contents and incoming data.

Write and erase operations require the Write Enable Latch to be set. The model also represents BUSY periods using simulation delays.

### 3. SPI Transmit Logic

The transmit logic shifts status-register values, JEDEC identification bytes, and memory data out through MISO.

## State Machine

The design uses the following states:

| State | Description |
|---|---|
| `CMD_STATE` | Receives and decodes a command |
| `STATUS_STATE` | Transmits status-register data |
| `ADDRESS_STATE` | Receives the 24-bit address |
| `PROGRAM_STATE` | Programs incoming data into memory |
| `READ_STATE` | Transmits memory data |
| `DATA_STATE` | Handles commands that require no further address or data processing |
| `JEDEC_STATE` | Transmits the JEDEC ID |

## Memory Model and Limitations

This is a **behavioral simulation model**, not a complete physical Flash implementation.

- Memory capacity is limited to 65,536 bytes (64 KB).
- The SPI protocol accepts 24-bit addresses, but only the lower 16 bits select memory locations.
- `D8h` and `C7h` both erase the entire modeled memory because the model is limited to 64 KB.
- BUSY durations are simplified simulation values, not the actual device's timing specifications.
- The JEDEC ID response is fixed to `EFh 40h 17h`.
- The implementation models selected commands and does not reproduce every feature or timing requirement of a physical W25Q64 device.
- The current model is intended for behavioral simulation and educational verification, not direct hardware deployment.

## Project Structure

The project uses the following primary files:

```text
SPI-Flash-RTL/
├── Spi_flash.v
├── Spi_flash_tb.v
└── README.md
```

- `Spi_flash.v` — Behavioral SPI Flash RTL implementation.
- `Spi_flash_tb.v` — Self-checking testbench used to verify supported commands and operation sequences.
- `README.md` — Project description, supported commands, design details, and simulation instructions.

## Tools and Technologies

- **Language:** Verilog HDL
- **Simulator:** ModelSim Intel FPGA Edition
- **Verification:** Self-checking Verilog testbench
- **Version Control:** Git and GitHub

## Running the Simulation

### Prerequisites

Install ModelSim and ensure that `Spi_flash.v` and `Spi_flash_tb.v` are available in your ModelSim working directory.

### Step 1: Compile the RTL

```tcl
vlog Spi_flash.v
```

### Step 2: Compile the Testbench

```tcl
vlog Spi_flash_tb.v
```

### Step 3: Load the Simulation

```tcl
vsim -gui work.spi_flash_tb
```

### Step 4: Run the Testbench

```tcl
run -all
```

The testbench executes the supported command sequences, checks expected results, and reports the number of passed and failed tests.

## Verification Results

The comprehensive regression testbench was run in ModelSim.

| Metric | Result |
|---|---:|
| Tests passed | 28 |
| Tests failed | 0 |
| Compilation errors | 0 |
| Compilation warnings | 0 |

The testbench checks command behavior, write-enable protection, status-register values, memory programming and readback, erase behavior, BUSY status, JEDEC ID, and preservation of data outside the targeted 32 KB erase block.

**Verified regression result:**

```text
TOTAL PASSED = 28
TOTAL FAILED = 0
ALL TESTS PASSED
SPI FLASH RTL MODEL VERIFIED
```

These results represent the tested version of the RTL and testbench. Re-run the regression after making further modifications.

## Future Improvements

Potential extensions to the project include:

- Expand the memory model to support a larger address space.
- Improve READ-state register ownership and reset handling.
- Refactor BUSY and WEL control into a cleaner single-owner architecture.
- Add page-boundary wrapping and additional Flash command behavior.
- Improve timing accuracy against the selected device datasheet.
- Add waveform screenshots and transaction-level documentation.
- Extend verification with more boundary and malformed-command tests.

## Learning Outcomes

This project provided practical experience with:

- SPI serial communication and Mode 0 timing
- Verilog behavioral modeling
- Finite-state-machine design
- Serial-to-parallel and parallel-to-serial data handling
- NOR Flash programming and erase behavior
- Testbench development and self-checking verification
- Debugging and waveform inspection in ModelSim

## Author

**Abhinav Dahake**

Electronics Engineering Student

**Project:** SPI Flash Behavioral RTL Model  
**Domain:** Digital Design, Verilog HDL, Embedded Systems, RTL Verification

---

*This project is an educational behavioral model inspired by the command interface of a Winbond W25Q64-style SPI Flash device. It is not an official implementation or a drop-in replacement for the physical device.*
