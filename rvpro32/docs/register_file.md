# RVPRO32 Register File Specification

**Document Version:** 1.0  
**Status:** Draft  
**Module:** `regfile.v`  
**Owner:** RVPRO32 Hardware Track  
**Author:** Cuong Ho

---

# 1. Purpose

The Register File (RF) stores the 32 General Purpose Registers (GPRs) defined by the RISC-V ISA.

It provides:

- Two independent read ports
- One write port
- Zero-latency combinational reads
- Synchronous writes
- Constant-zero register (x0)

The register file is used during the **Instruction Decode (ID)** stage.

---

# 2. References

- RISC-V Unprivileged ISA Specification v2.2+
- RV32I Base ISA
- RV32M Extension
- RV32A Extension
- RV32F Extension (Floating-point register file is implemented separately)

---

# 3. Features

| Feature | Supported |
|----------|-----------|
| 32 Registers | ✔ |
| Register Width | 32-bit |
| Read Ports | 2 |
| Write Ports | 1 |
| x0 Hardwired to Zero | ✔ |
| Combinational Read | ✔ |
| Synchronous Write | ✔ |
| Write Enable | ✔ |
| Parameterizable Width | Optional |
| Parameterizable Depth | Optional |

---

# 4. Register Map

| Register | ABI Name | Description |
|----------|----------|-------------|
| x0 | zero | Constant Zero |
| x1 | ra | Return Address |
| x2 | sp | Stack Pointer |
| x3 | gp | Global Pointer |
| x4 | tp | Thread Pointer |
| x5-x7 | t0-t2 | Temporary |
| x8-x9 | s0-s1 | Saved Registers |
| x10-x17 | a0-a7 | Function Arguments |
| x18-x27 | s2-s11 | Saved Registers |
| x28-x31 | t3-t6 | Temporary |

---

# 5. Interface

## Inputs

| Signal | Width | Description |
|---------|------|-------------|
| clk | 1 | System clock |
| rst_n | 1 | Active-low reset (optional) |
| rs1_addr | 5 | Read Address Port 1 |
| rs2_addr | 5 | Read Address Port 2 |
| rd_addr | 5 | Write Address |
| rd_data | XLEN | Write Data |
| rd_we | 1 | Write Enable |

---

## Outputs

| Signal | Width | Description |
|---------|------|-------------|
| rs1_data | XLEN | Read Data Port 1 |
| rs2_data | XLEN | Read Data Port 2 |

---

# 6. Functional Requirements

## RF-001

The register file shall contain exactly **32 registers**.

---

## RF-002

Each register shall be **XLEN bits wide**.

For RVPRO32

```
XLEN = 32
```

---

## RF-003

The register file shall provide two independent read ports.

```
rs1

↓

Register File

↓

rs1_data
```

```
rs2

↓

Register File

↓

rs2_data
```

---

## RF-004

The register file shall provide one write port.

```
rd_addr

rd_data

rd_we

↓

Register File
```

---

## RF-005

Reads shall be **combinational**.

Reading shall not require a clock edge.

---

## RF-006

Writes shall occur on the rising edge of `clk`.

```
posedge clk
```

---

## RF-007

Writes occur only when

```
rd_we == 1
```

---

## RF-008

Register x0 shall always contain

```
32'h00000000
```

regardless of write attempts.

Example

```
Write:

rd = 0

rd_data = FFFFFFFF

↓

Ignored
```

---

## RF-009

Reading x0 shall always return

```
0x00000000
```

---

## RF-010

Reset shall initialize every register to zero.

*(Optional for FPGA implementation. Many commercial CPUs leave registers undefined after reset except x0.)*

---

# 7. Read Operation

Reads are asynchronous.

```
rs1_data = RF[rs1_addr]

rs2_data = RF[rs2_addr]
```

Special case

```
if(rs1_addr==0)

rs1_data = 0
```

```
if(rs2_addr==0)

rs2_data = 0
```

---

# 8. Write Operation

At every rising edge

```
if(rd_we)

RF[rd_addr] <= rd_data
```

except

```
rd_addr == 0
```

which is ignored.

---

# 9. Read During Write Behavior

If

```
rd_addr == rs1_addr
```

during the same cycle

the behavior depends on implementation.

## Option A (Recommended)

Register file returns **old data**.

Forwarding Unit resolves hazards.

Advantages

- Simpler RTL
- Matches FPGA BRAM inference
- Standard in many CPUs

---

## Option B

Bypass inside Register File

```
if(rs1==rd && rd_we)

rs1_data = rd_data
```

Advantages

- One less forwarding case

Disadvantages

- Larger combinational path
- Less modular

**RVPRO32 Decision**

Use **Option A**.

Forwarding is handled by `hazard_unit.v`.

---

# 10. Timing

Read

```
Address

↓

MUX

↓

Register Array

↓

Read Data
```

No clock.

---

Write

```
posedge clk

↓

Decoder

↓

Register Update
```

---

# 11. Resource Estimate

Artix-7

| Resource | Estimate |
|-----------|----------|
| Flip-Flops | 1024 |
| LUT | 50~120 |
| BRAM | 0 |

Recommended implementation:

Distributed Registers

Not Block RAM.

Reason

- Only 32×32 bits
- Two asynchronous read ports
- Better timing

---

# 12. Verification Plan

## Test 1

Write

```
x5 = 12345678
```

Read

```
x5

↓

12345678
```

PASS

---

## Test 2

Write

```
x0 = FFFFFFFF
```

Read

```
x0

↓

00000000
```

PASS

---

## Test 3

Write every register

```
x1

↓

1

x2

↓

2

...

x31

↓

31
```

Verify all values.

---

## Test 4

Random writes

100000 cycles

Compare against reference model.

---

## Test 5

Random read/write simultaneously.

---

## Test 6

Reset behavior.

---

# 13. Assertions

```systemverilog
assert(RF[0] == 32'h0);
```

---

```systemverilog
assert(rs1_addr == 0 |-> rs1_data == 0);
```

---

```systemverilog
assert(rs2_addr == 0 |-> rs2_data == 0);
```

---

```systemverilog
assert(!(rd_we && rd_addr==0) || RF[0]==0);
```

---

# 14. Future Extensions

- Dual-issue register file (4 Read / 2 Write ports)
- ECC/Parity protection
- Clock gating for low power
- Multi-bank organization
- Register renaming support (Out-of-Order CPU)

---

# 15. Design Decisions

| Decision | Choice |
|-----------|--------|
| Read Ports | 2 |
| Write Ports | 1 |
| Read Type | Asynchronous |
| Write Type | Synchronous |
| Read-after-Write | Old Data |
| Hazard Handling | Forwarding Unit |
| x0 | Hardwired Zero |
| Storage | Flip-Flops (Distributed Registers) |
| Parameterizable | XLEN only |
