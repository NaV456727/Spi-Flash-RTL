# SPI Flash RTL

Behavioral RTL implementation of an SPI Flash memory using Verilog HDL.

## Overview

This project implements an SPI Flash slave and simulates its operation using ModelSim.

The SPI interface uses **Mode 0** with the following signals:

- **CS** — Chip Select
- **SCLK** — SPI Clock
- **MOSI** — Master Out, Slave In
- **MISO** — Master In, Slave Out

## Implemented Commands

| Command | Hex | Description |
|---|---|---|
| Write Enable | `06h` | Enables write operations |
| Write Disable | `04h` | Disables write operations |
| Read Status Register | `05h` | Reads status information |
| Page Program | `02h` | Programs data into flash memory |
| Read Data | `03h` | Reads data from flash memory |

## Simulation

The current testbench performs a write and readback operation:

Write Enable
     ↓
Page Program
     ↓
Address: 0010h
     ↓
Data: DE AD BE EF
     ↓
Read Data
     ↓
DE AD BE EF

Simulation is performed using ModelSim Intel FPGA Starter Edition.

# Project Structure

SPI-Flash-RTL/
├── rtl/
│   └── spi_flash.v
├── tb/
│   └── spi_flash_tb.v
├── README.md
└── .gitignore

# Status

Work in progress. Additional SPI Flash commands and verification features will be added as the project develops.
