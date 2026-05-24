# UART RTL Design & Verification

> Full-duplex UART transceiver implemented in Verilog — fixed 9600 baud,
> loopback-verified testbench with timeout watchdog and pass/fail reporting.

---

## 📌 Overview

UART (Universal Asynchronous Receiver-Transmitter) is one of the most widely
used serial communication protocols in embedded systems. Unlike SPI or I2C,
UART is **asynchronous** — no shared clock is required between transmitter and
receiver. Both sides agree on a fixed **baud rate** before communication begins.

### How UART works:
- **Idle state:** The line stays HIGH when no data is being sent.
- **Start bit:** Transmission begins with a LOW pulse to signal the receiver.
- **Data bits:** 8 data bits are sent LSB-first.
- **Stop bit:** One HIGH bit marks the end of a frame.

```
IDLE  START   D0  D1  D2  D3  D4  D5  D6  D7   STOP
 1  |  0   |  x   x   x   x   x   x   x   x  |  1
```

---

## ⚙️ Features

- ✅ Full-duplex UART: independent TX and RX modules
- ✅ Fixed baud rate: 9600 bps @ 50 MHz system clock
- ✅ Separate baud generators: TX uses ×1 tick, RX uses ×16 oversampling tick
- ✅ 16× oversampling RX with bit-center sampling for robust data recovery
- ✅ 2-FF metastability synchronizer on RX input
- ✅ Frame error detection on stop-bit verification
- ✅ FSM-based control for both TX and RX (4-state each)
- ✅ Loopback testbench with timeout watchdog and pass/fail counter

---

## 🛠️ Tech Stack

| Area       | Details                  |
|:-----------|:-------------------------|
| HDL        | Verilog                  |
| Simulation | Icarus Verilog, ModelSim |
| Waveform   | GTKWave                  |
| Protocol   | UART (async serial)      |

---

## 📁 Project Structure

```
uart-project/
├── rtl/
│   ├── baud_gen.v       # Baud rate generator (parametrizable)
│   ├── uart_tx.v        # Transmitter module
│   ├── uart_rx.v        # Receiver module
│   └── uart_top.v       # Top-level integration
└── uart_tb.v            # Loopback testbench
```

---

## 🔧 RTL Design

### Baud Generator (`baud_gen.v`)

A parametrizable counter that divides the 50 MHz system clock down to the
required baud tick. Two instances are used in `uart_top`:

| Instance    | BAUD_RATE param  | Purpose               |
|:------------|:-----------------|:----------------------|
| `u_baud_tx` | 9 600            | TX — 1 tick per bit   |
| `u_baud_rx` | 153 600 (×16)    | RX — 16 ticks per bit |

- Counter width: 13 bits (MAX_COUNT = 5207 for TX)
- Tick is asserted HIGH for exactly 1 clock cycle

---

### TX Module (`uart_tx.v`)

The transmitter is controlled by a **4-state FSM**:

```
IDLE → START → DATA → STOP
```

| State | Description                                               |
|:------|:----------------------------------------------------------|
| IDLE  | Line held HIGH, `tx_busy` deasserted                     |
| START | Captures `tx_data` into shift register, asserts `tx_busy`|
| DATA  | Drives start bit LOW on first tick                        |
| STOP  | Shifts out 8 data bits LSB-first, one per baud tick      |

- `tx_busy` remains HIGH throughout START → DATA → STOP, preventing
  new transmission requests from being accepted mid-frame.
- Data is loaded into an 8-bit shift register and shifted right each tick.

---

### RX Module (`uart_rx.v`)

The receiver uses **16× oversampling** to accurately sample incoming data:

```
IDLE → START → DATA → STOP
```

| State | Description                                                         |
|:------|:--------------------------------------------------------------------|
| IDLE  | Monitors for falling edge on synchronized RX line (gated on tick)  |
| START | Waits 8 ticks to align to center of start bit; validates LOW       |
| DATA  | Samples each bit at tick 16 (bit center); shifts into register     |
| STOP  | Samples stop bit at tick 16; asserts `rx_done` or `rx_error`      |

- **2-FF synchronizer** (`rx_sync1`, `rx_sync2`) on the raw `rx` input
  prevents metastability from propagating into the FSM.
- Start detection is **gated on tick** boundary to minimize phase offset.
- `rx_done` and `rx_error` are pulsed HIGH for exactly 1 clock cycle.
- A missing or corrupt stop bit (LOW at sample point) sets `rx_error`
  (frame error) instead of `rx_done`.

---

## ✅ Verification

### Testbench Strategy

A **directed loopback testbench** connects `tx` directly to `rx`
(`wire rx = tx`) and sends 11 test vectors through a reusable `send_byte`
task. Each call includes a **timeout watchdog** (2 ms / 100 000 cycles)
and automatically increments `pass_cnt` or `fail_cnt`.

### Test Vectors

| # | Test Group          | Vectors             | Purpose                                       |
|:--|:--------------------|:--------------------|:----------------------------------------------|
| 1 | Alternating bits    | 0x55, 0xAA          | Catch bit-inversion and shift-direction bugs  |
| 2 | Boundary values     | 0x00, 0xFF          | Verify start/stop boundaries at all-0/all-1   |
| 3 | Asymmetric patterns | 0x31, 0x12, 0xC3    | Expose non-symmetric bit-ordering errors      |
| 4 | Sequential stream   | 0x00→0x04 (5 bytes) | Verify back-to-back frame handling            |

### Pass/Fail Reporting

```
===== BẮT ĐẦU TEST UART =====
[PASS] Sent: 0x55 | Received: 0x55
[PASS] Sent: 0xAA | Received: 0xAA
...
Tổng: PASS = 11 | FAIL = 0 | TOTAL = 11
>>> TẤT CẢ TEST ĐỀU PASS ✓
```

### Bug Found & Fixed

During waveform analysis, an **RX sampling phase-alignment bug** was identified:

- **Root cause:** RX FSM entered START state on any falling edge of `rx_sync2`,
  without waiting for a tick boundary — causing a phase offset of up to ±1 tick
  (~1/16 bit period) in the oversampling counter.
- **Fix:** Gated the IDLE → START transition on `tick` so the 16× counter
  always starts aligned to the baud tick grid, ensuring consistent
  bit-center sampling across all baud rates.

---

## 🚀 How to Run

### Simulate with Icarus Verilog

```bash
git clone https://github.com/dinhhieu912/uart_verilog.git
cd uart_verilog

iverilog -o uart_sim uart_tb.v rtl/uart_top.v rtl/uart_tx.v \
         rtl/uart_rx.v rtl/baud_gen.v
vvp uart_sim
gtkwave uart_tb.vcd
```

### Simulate with ModelSim

```bash
vlog rtl/baud_gen.v rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v uart_tb.v
vsim uart_tb
run -all
```

---

## 📬 Contact

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/hiếu-trần-59a741305/)
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=flat-square&logo=gmail&logoColor=white)](mailto:dinhhieu9125@gmail.com)
