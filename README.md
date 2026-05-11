# UART RTL Design & Verification 

> Full-duplex UART transceiver implemented in Verilog — configurable baud rate, parity, and stop-bit options with directed testbench verification.

---

## 📌 Overview

UART (Universal Asynchronous Receiver-Transmitter) is a serial communication protocol widely used in embedded systems. This project implements a full-duplex UART transceiver (TX + RX) in Verilog, verified through a directed testbench covering normal operation and edge cases.

---

## ⚙️ Features

- Full-duplex UART: TX and RX modules
- Configurable baud rate: 9600 / 19200 / 115200 bps
- Programmable parity: None / Even / Odd
- Configurable stop bits: 1 or 2
- 16× oversampling RX logic for robust data recovery
- FSM-based control for TX and RX datapath

---

## 🛠️ Tech Stack

| Area         | Details                          |
|:-------------|:---------------------------------|
| HDL          | Verilog                          |
| Simulation   | Icarus Verilog, ModelSim         |
| Waveform     | GTKWave                          |
| Synthesis    | Intel Quartus                    |
| Protocol     | UART (async serial)              |

---

## 📁 Project Structure

```
uart-project/
├── rtl/
│   ├── uart_tx.v        # Transmitter module
│   ├── uart_rx.v        # Receiver module
│   └── uart_top.v       # Top-level integration
├── tb/
│   ├── tb_uart_tx.v     # TX testbench
│   └── tb_uart_rx.v     # RX testbench
└── README.md
```

---

## ✅ Verification

- 20+ directed test vectors covering:
  - Normal read/write transactions
  - Parity error injection
  - Framing error detection
  - Baud rate mismatch
- Identified and resolved RX sampling timing bug via GTKWave waveform analysis
- Zero false positives across all test cases

---

## 📊 Simulation Results

| Test Case            | Result  |
|:---------------------|:--------|
| Normal TX/RX         | ✅ Pass |
| Parity Error         | ✅ Pass |
| Framing Error        | ✅ Pass |
| Baud Rate Mismatch   | ✅ Pass |
| Loopback Test        | ✅ Pass |

---

## 🚀 How to Run

```bash
# Clone the repo
git clone https://github.com/dinhhieu912/uart-rx-verilog.git
cd uart-rx-verilog

# Simulate with Icarus Verilog
iverilog -o uart_sim tb/tb_uart_rx.v rtl/uart_rx.v
vvp uart_sim

# View waveform
gtkwave dump.vcd
```

---

## 📬 Contact

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/hi%E1%BA%BFu-tr%E1%BA%A7n-59a741305/)
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=flat-square&logo=gmail&logoColor=white)](mailto:dinhhieu9125@gmail.com)
