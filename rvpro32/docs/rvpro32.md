# Phase 0-1: RV32I Pipeline (Chi tiết)

Mục tiêu của Phase 0-1 **không phải tạo một CPU hoàn chỉnh**, mà là xây dựng một **RV32I Core** có thể chạy được chương trình C đơn giản trên Verilator và FPGA.

---

# Stage 0.0 - Project Infrastructure

## Mục tiêu

Thiết lập toàn bộ môi trường phát triển.

## Tasks

- Cài Vivado
- Cài Verilator
- Cài GTKWave
- Cài riscv-gnu-toolchain
- Tạo Git repository
- Thiết lập CI (tùy chọn)
- Tạo Makefile

## Deliverables

```
rvpro32/

rtl/

sim/

tb/

docs/

scripts/

sw/

fpga/

verif/
```

---

# Stage 0.1 - Coding Style & RTL Infrastructure

## Mục tiêu

Thống nhất coding convention trước khi viết RTL.

## Tasks

- Naming convention
- Reset convention
- Clock convention
- Parameter convention
- File organization
- Common package
- Macro definitions

Ví dụ

```
rtl/core

rtl/common

rtl/include

rtl/interfaces
```

---

# Stage 0.2 - Basic Components

Viết các module nhỏ trước.

## Register

```
register.v
```

## Multiplexer

```
mux2

mux4

mux8
```

## Decoder

```
decoder.v
```

## Sign Extension

```
sign_extend.v
```

## Comparator

```
compare.v
```

## Barrel Shifter

```
barrel_shift.v
```

## Deliverables

Một thư viện RTL cơ bản.

---

# Stage 0.3 - ALU

## Mục tiêu

Hoàn thành ALU của RV32I.

Operations

```
ADD

SUB

AND

OR

XOR

SLL

SRL

SRA

SLT

SLTU
```

## Verification

Unit Test

```
ADD

overflow

negative

carry

shift

...
```

---

# Stage 0.4 - Register File

## Mục tiêu

Thiết kế Register File.

Specification

```
32 Registers

2 Read Ports

1 Write Port

x0 hardwired = 0
```

## Verification

- Read after write
- x0 immutable
- Simultaneous read

---

# Stage 0.5 - Immediate Generator

Sinh immediate cho toàn bộ RV32I.

```
I

S

B

U

J
```

---

# Stage 0.6 - Instruction Decoder

Decode

```
opcode

funct3

funct7

rd

rs1

rs2
```

Output

```
ALU Control

Branch

Load

Store

Jump

CSR (reserved)
```

---

# Stage 0.7 - Program Counter

Thiết kế

```
PC Register

PC+4

Branch Target

Jump Target
```

---

# Stage 0.8 - Instruction Memory

Ban đầu

```
ROM

$readmemh()
```

Sau này mới thay bằng

```
AXI

Cache
```

---

# Stage 0.9 - Data Memory

Temporary

```
Simple RAM
```

Hỗ trợ

```
LB

LH

LW

SB

SH

SW
```

---

# Stage 0.10 - Single Cycle CPU

Ghép

```
PC

↓

Instruction Memory

↓

Decoder

↓

Register File

↓

Immediate

↓

ALU

↓

Data Memory

↓

Write Back
```

CPU lúc này **chưa pipeline**.

Đây là milestone cực kỳ quan trọng.

## Deliverables

```
hello_world

memory_test

alu_test
```

---

# Stage 0.11 - Verilator Testbench

Tạo testbench.

Có thể

```
Load ELF

↓

Execute

↓

Dump Waveform

↓

Compare Result
```

---

# Stage 0.12 - FPGA Bring-up

Nạp lên Arty A7.

Demo

```
LED Blink

UART Hello World
```

---

# Stage 1.0 - Pipeline Planning

Bắt đầu chuyển sang pipeline.

Tách

```
IF

ID

EX

MEM

WB
```

Vẽ datapath hoàn chỉnh.

---

# Stage 1.1 - IF Stage

Module

```
if_stage.v
```

Bao gồm

```
PC

PC+4

Instruction Fetch
```

---

# Stage 1.2 - IF/ID Register

Pipeline Register đầu tiên.

```
Instruction

PC

PC+4
```

---

# Stage 1.3 - ID Stage

Bao gồm

```
Register File

Immediate Generator

Decode
```

---

# Stage 1.4 - ID/EX Register

Lưu

```
Operands

Immediate

Destination Register

Control Signals
```

---

# Stage 1.5 - EX Stage

Bao gồm

```
ALU

Branch Comparator

Branch Target
```

---

# Stage 1.6 - EX/MEM Register

Lưu

```
ALU Result

Store Data

Destination Register
```

---

# Stage 1.7 - MEM Stage

Bao gồm

```
Load

Store

Memory Access
```

---

# Stage 1.8 - MEM/WB Register

Lưu

```
Load Data

ALU Result

Destination Register
```

---

# Stage 1.9 - WB Stage

Write Back

```
Register File
```

---

# Stage 1.10 - Hazard Detection

Xử lý

```
RAW

Load-use

Pipeline Stall
```

---

# Stage 1.11 - Forwarding Unit

Forward

```
EX → EX

MEM → EX
```

---

# Stage 1.12 - Pipeline Flush

Flush khi

```
Branch Taken

Jump

Exception (future)
```

---

# Stage 1.13 - Pipeline Verification

Test

- Arithmetic
- Load
- Store
- Branch
- Jump
- Forwarding
- Stall
- Hazard
- Bubble

---

# Stage 1.14 - RISC-V Compliance

Chạy

```
riscv-arch-test

RV32I
```

Toàn bộ phải PASS.

---

# Stage 1.15 - Milestone

Sau khi hoàn thành Phase 1, CPU sẽ có các đặc điểm:

| Thành phần | Trạng thái |
|------------|------------|
| RV32I ISA | ✅ |
| 5-stage Pipeline | ✅ |
| Forwarding | ✅ |
| Hazard Detection | ✅ |
| Stall Logic | ✅ |
| Branch Flush | ✅ |
| Single-cycle Memory | ✅ |
| Verilator Testbench | ✅ |
| FPGA chạy được | ✅ |
| RISC-V Compliance | ✅ |

Đây sẽ là **nền móng** cho tất cả các phase tiếp theo (M Extension, CSR, MMU, Cache, Branch Prediction, FPU...). Sau Phase 1, kiến trúc pipeline nên được giữ ổn định; các tính năng mới chủ yếu được bổ sung bằng cách mở rộng các stage hiện có thay vì thay đổi cấu trúc cơ bản.
