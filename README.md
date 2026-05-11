# UART RTL Design & Verification

> Full-duplex UART transceiver implemented in Verilog — configurable baud rate, parity, and stop-bit options with directed testbench verification.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/hi%E1%BA%BFu-tr%E1%BA%A7n-59a741305/)
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=flat-square&logo=gmail&logoColor=white)](mailto:dinhhieu9125@gmail.com)

---

## 📌 Overview

UART (Universal Asynchronous Receiver-Transmitter) is one of the most widely used serial communication protocols in embedded systems. Unlike SPI or I2C, UART is **asynchronous** — meaning it does not require a shared clock signal between transmitter and receiver. Instead, both sides agree on a fixed **baud rate** (bits per second) before communication begins.

### How UART works:
- **Idle state:** The line stays HIGH when no data is being sent.
- **Start bit:** Transmission begins with a LOW pulse (start bit) to signal the receiver.
- **Data bits:** 8 data bits are sent LSB-first.
- **Parity bit (optional):** An extra bit for basic error detection.
- **Stop bit:** One or two HIGH bits to mark the end of a frame.

```
IDLE  START   D0  D1  D2  D3  D4  D5  D6  D7  PARITY  STOP
 1  |  0   |  x   x   x   x   x   x   x   x  |   x   |  1
```

This project implements a **full-duplex UART transceiver** (TX + RX) in Verilog, verified through a directed testbench covering normal operation, boundary cases, and fault injection.

---

## ⚙️ Features

- ✅ Full-duplex UART: independent TX and RX modules
- ✅ Configurable baud rate: 9600 / 19200 / 115200 bps
- ✅ Programmable parity: None / Even / Odd
- ✅ Configurable stop bits: 1 or 2
- ✅ 16× oversampling RX logic for robust data recovery
- ✅ FSM-based control for TX and RX datapath
- ✅ Loopback test support

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

## 🔧 RTL Design

### TX Module (`uart_tx.v`)

The transmitter is controlled by a **4-state FSM**:

```
IDLE → START → DATA → STOP
```

| State   | Description                                      |
|:--------|:-------------------------------------------------|
| IDLE    | Line held HIGH, waiting for transmit request     |
| START   | Drives line LOW for one baud period (start bit)  |
| DATA    | Shifts out 8 data bits LSB-first                 |
| STOP    | Drives line HIGH for 1 or 2 baud periods         |

- A **baud rate generator** divides the system clock to produce the correct bit timing.
- Data is loaded into a shift register and shifted out one bit per baud period.

---

### RX Module (`uart_rx.v`)

The receiver uses **16× oversampling** to accurately sample incoming data:

```
IDLE → START_DETECT → SAMPLE → STOP_CHECK
```

| State         | Description                                              |
|:--------------|:---------------------------------------------------------|
| IDLE          | Monitors line for falling edge (start bit detection)     |
| START_DETECT  | Waits 8 oversampling ticks to confirm valid start bit    |
| SAMPLE        | Samples each data bit at the center (tick 16)            |
| STOP_CHECK    | Verifies stop bit; flags framing error if missing        |

- **16× oversampling** means the receiver samples each bit 16 times per baud period, then reads at the midpoint — this makes it robust against clock drift and noise.
- Parity is checked after all 8 data bits are received.

---

## ✅ Verification

### Testbench Strategy

A **directed testbench** was written to apply specific input stimuli and check expected outputs. Each test case targets a distinct behavior or fault scenario.

### Test Cases

| # | Test Case              | Description                                              | Result  |
|:--|:-----------------------|:---------------------------------------------------------|:--------|
| 1 | Normal TX/RX           | Send 0x00–0xFF, verify received data matches             | ✅ Pass |
| 2 | Parity Error Injection | Flip parity bit mid-frame, check error flag asserted     | ✅ Pass |
| 3 | Framing Error          | Missing stop bit, check framing error flag               | ✅ Pass |
| 4 | Baud Rate Mismatch     | TX at 115200, RX at 9600 — verify data corruption caught | ✅ Pass |
| 5 | Loopback Test          | Connect TX output directly to RX input                   | ✅ Pass |
| 6 | Back-to-back frames    | Send multiple frames without gap                         | ✅ Pass |
| 7 | All zeros (0x00)       | Verify start/stop bit boundaries correct                 | ✅ Pass |
| 8 | All ones (0xFF)        | Verify no false start bit detection                      | ✅ Pass |

### Bug Found & Fixed

During waveform analysis in GTKWave, an **RX sampling timing bug** was identified:
- **Root cause:** The RX was sampling at tick 15 instead of tick 16 (center of bit), causing occasional bit misreads at higher baud rates.
- **Fix:** Adjusted the oversampling counter threshold from 15 to 16 in the SAMPLE state logic.

---

## 📊 Synthesis Results

> Synthesized on **Intel Quartus** targeting Intel Cyclone IV FPGA.

| Metric              | Value          |
|:--------------------|:---------------|
| Total LUTs          | ~85            |
| Flip-Flops          | ~40            |
| Fmax                | ~125 MHz       |
| Target Clock        | 50 MHz         |
| Timing Slack        | Positive ✅    |

---

## 🚀 How to Run

### Simulate with Icarus Verilog

```bash
# Clone the repo
git clone https://github.com/dinhhieu912/uart-rx-verilog.git
cd uart-rx-verilog

# Compile
iverilog -o uart_sim tb/tb_uart_rx.v rtl/uart_rx.v

# Run simulation
vvp uart_sim

# View waveform
gtkwave dump.vcd
```

### Simulate with ModelSim

```bash
vlog rtl/uart_rx.v tb/tb_uart_rx.v
vsim tb_uart_rx
run -all
```

---

## 📬 Contact

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/hi%E1%BA%BFu-tr%E1%BA%A7n-59a741305/)
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=flat-square&logo=gmail&logoColor=white)](mailto:dinhhieu9125@gmail.com)
