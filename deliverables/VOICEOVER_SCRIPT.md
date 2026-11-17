# Voice-over script — How DRAM Works

Timings match the caption beats in each episode. The videos are mixed at roughly −20 dB for the
ambient bed, so narration can sit on top without remixing. Read at a calm ~150 words per minute.

## EP01 — The Leaky Bucket (0:46)

| In | Out | Line |
|----|-----|------|
| 0:01 | 0:05 | Inside every memory chip there are billions of tiny buckets. Each one holds exactly one bit. |
| 0:06 | 0:12 | A DRAM cell is two parts: a transistor, and a capacitor. Charge in the capacitor means 1. No charge means 0. |
| 0:13 | 0:19 | The transistor is a gate. When the wordline turns it on, charge can flow from the bitline into the capacitor. |
| 0:20 | 0:26 | But the capacitor is a bucket that always leaks. Even with the power on, the charge drains away in milliseconds. |
| 0:27 | 0:33 | So before the bit disappears, the chip reads it, amplifies it, and writes it straight back. That is a refresh. |
| 0:34 | 0:40 | Every row gets refreshed every sixty-four milliseconds. Billions of cells, over and over, forever. |
| 0:41 | 0:45 | Next: the refresh cycle, and what it costs. |

## EP02 — The Refresh Cycle (0:44)

| In | Out | Line |
|----|-----|------|
| 0:01 | 0:05 | A stored bit is not stable. It is a race against leakage. |
| 0:06 | 0:13 | The charge drains in a curve. After a few dozen milliseconds, the difference between a 1 and a 0 is almost nothing. |
| 0:14 | 0:21 | The sense amplifier solves that. It looks at an almost invisible charge and decides: this was a one, or this was a zero. |
| 0:23 | 0:30 | Refresh is simple: read a row, amplify every bit, write it back. Then move to the next row. |
| 0:31 | 0:37 | The whole array has to be refreshed every sixty-four milliseconds. That is a steady tax paid in time and power. |
| 0:38 | 0:44 | Next: how an address becomes data. Rows, columns, and banks. |

## EP03 — Rows, Columns, Banks (0:40)

| In | Out | Line |
|----|-----|------|
| 0:01 | 0:05 | You ask memory for eight bytes. The chip has to find them among billions of cells. |
| 0:06 | 0:13 | Every cell has a two-part address: a row and a column. The row comes first. |
| 0:14 | 0:20 | One wordline rises, and every cell on that row connects to its bitline at the same time. Thousands of bits, all at once. |
| 0:21 | 0:27 | Below the array, a bank of sense amplifiers reads the entire row and holds it. This is why a row is the unit of access. |
| 0:28 | 0:34 | Then the column multiplexer picks out the bits you actually asked for, and they leave on the data bus. |
| 0:35 | 0:40 | Next: the timing of a real read. Activate, read, precharge. |

## EP04 — The Read Transaction (0:44)

| In | Out | Line |
|----|-----|------|
| 0:01 | 0:05 | A memory read is not a lookup. It is a transaction with a clock, a command, and a wait. |
| 0:06 | 0:13 | First the controller issues Activate. The row begins to open, and the chip needs time: tRCD, row to column delay. |
| 0:15 | 0:21 | Only then can the read command go out. Then comes CAS latency: a fixed number of clock cycles before the data appears. |
| 0:23 | 0:29 | The data leaves in a burst, four beats here, eight on modern DDR. That part is fast. The waiting is what costs you. |
| 0:31 | 0:37 | Finally precharge closes the row and resets the bitlines for the next access. That is tRP. |
| 0:38 | 0:44 | Next: how DDR doubles the transfer rate. |

## EP05 — Double Data Rate (0:42)

| In | Out | Line |
|----|-----|------|
| 0:01 | 0:05 | The clock is the heartbeat of the bus. Early SDRAM moved one piece of data per cycle. |
| 0:06 | 0:12 | DDR moves data on the rising edge and on the falling edge. Same clock, twice the transfers. |
| 0:14 | 0:20 | Modern DDR also reads eight beats per column access, a prefetch of eight. Eight beats of eight bytes is sixty-four bytes. One cache line. |
| 0:21 | 0:27 | Widen the bus to sixty-four pins and the numbers get serious. |
| 0:29 | 0:35 | DDR5-5600: 5600 million transfers per second, times eight bytes, is 44.8 gigabytes per second per channel. |
| 0:36 | 0:42 | Next: how all of this fits on the module in your machine. |

## EP06 — Inside a DIMM (0:44)

| In | Out | Line |
|----|-----|------|
| 0:01 | 0:05 | This is the memory you can hold: a DIMM, a small board with a connector and eight chips. |
| 0:06 | 0:13 | The chips on one side act as a rank. They answer together, eight bits each, to build a sixty-four-bit word. |
| 0:15 | 0:21 | Inside each chip there are many banks. A bank can be busy while another is being refreshed or precharged. |
| 0:23 | 0:29 | The memory controller spreads addresses across channels, ranks and banks, so that no single bank becomes a bottleneck. |
| 0:31 | 0:37 | More channels mean more bandwidth. Lower latency comes from keeping rows open and from banks that can work in parallel. |
| 0:38 | 0:44 | That is DRAM: one leaky capacitor, repeated billions of times, kept honest by timing. |
