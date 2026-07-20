# RVPRO32 ALU Specification

**Document Version:** 1.0  
**Status:** Draft  
**Module:** `alu.v`  
**Owner:** RVPRO32 Hardware Track

---

# 1. Purpose

The Arithmetic Logic Unit (ALU) performs all integer arithmetic, logical, comparison, and shift operations required by the RV32I ISA.

The ALU is used during the **Execute (EX)** stage of the pipeline.

The ALU is purely combinational and produces its result within one clock cycle.

---

# 2. References

- RISC-V Unprivileged ISA Specification
- RV32I Base ISA
- RV32M Extension (Multiply/Divide handled by dedicated unit)
- RV32B Extension (future support)

---

# 3. Scope

This module implements:

- Integer arithmetic
- Logic operations
- Shift operations
- Signed/Unsigned comparison
- Branch comparison support
- Address calculation
- Overflow ignored (per RISC-V ISA)

Not included:

- Multiply
- Divide
- Floating Point
- CSR Operations

---

# 4. Features

| Feature | Supported |
|----------|-----------|
| XLEN | 32-bit |
| Combinational | ✔ |
| Arithmetic | ✔ |
| Logic | ✔ |
| Compare | ✔ |
| Shift | ✔ |
| Branch Compare | ✔ |
| Address Generation | ✔ |
| Multiply | External Unit |
| Divide | External Unit |

---

# 5. Interface

## Inputs

| Signal | Width | Description |
|---------|------|-------------|
| op_a | XLEN | Operand A |
| op_b | XLEN | Operand B |
| alu_op | 5 | ALU Operation Code |

---

## Outputs

| Signal | Width | Description |
|---------|------|-------------|
| result | XLEN | ALU Result |
| zero | 1 | Result equals zero |
| less | 1 | Signed comparison |
| less_u | 1 | Unsigned comparison |

---

# 6. Functional Requirements

## ALU-001

The ALU shall operate on two XLEN-bit operands.

---

## ALU-002

The ALU shall be purely combinational.

No internal registers shall exist.

---

## ALU-003

The ALU shall support the following arithmetic operations.

| Operation | Description |
|------------|-------------|
| ADD | Addition |
| SUB | Subtraction |

---

## ALU-004

The ALU shall support logical operations.

| Operation |
|------------|
| AND |
| OR |
| XOR |

---

## ALU-005

The ALU shall support shift operations.

| Operation | Description |
|------------|-------------|
| SLL | Logical Left Shift |
| SRL | Logical Right Shift |
| SRA | Arithmetic Right Shift |

Shift amount shall use

```
op_b[4:0]
```

---

## ALU-006

The ALU shall support comparisons.

| Operation | Description |
|------------|-------------|
| SLT | Signed Less Than |
| SLTU | Unsigned Less Than |

Returned value

```
1

or

0
```

---

## ALU-007

The ALU shall generate branch comparison signals.

Supported comparisons

```
BEQ

BNE

BLT

BGE

BLTU

BGEU
```

These signals are used by the Branch Unit.

---

## ALU-008

The ALU shall ignore arithmetic overflow.

Example

```
FFFFFFFF

+

1

=

00000000
```

No overflow exception is generated.

---

# 7. ALU Operations

| ALU_OP | Instruction | Result |
|----------|-------------|--------|
| ADD | ADD ADDI AUIPC Load Store | A+B |
| SUB | SUB | A-B |
| AND | AND ANDI | A&B |
| OR | OR ORI | A\|B |
| XOR | XOR XORI | A^B |
| SLL | SLL SLLI | A<<B |
| SRL | SRL SRLI | A>>B |
| SRA | SRA SRAI | Arithmetic Shift |
| SLT | SLT SLTI | Signed Compare |
| SLTU | SLTU SLTIU | Unsigned Compare |
| COPY_A | LUI support | A |
| COPY_B | LUI | B |

---

# 8. Branch Support

Branch decisions

| Instruction | Condition |
|--------------|-----------|
| BEQ | op_a == op_b |
| BNE | op_a != op_b |
| BLT | signed(op_a)<signed(op_b) |
| BGE | signed(op_a)>=signed(op_b) |
| BLTU | unsigned(op_a)<unsigned(op_b) |
| BGEU | unsigned(op_a)>=unsigned(op_b) |

---

# 9. Timing

```
Operand A

        │

Operand B

        │

    ALU Decoder

        │

 Arithmetic / Logic

        │

    Output MUX

        │

      Result
```

Entire datapath shall be combinational.

---

# 10. Latency

| Operation | Latency |
|------------|---------|
| ADD | 1 cycle |
| SUB | 1 cycle |
| Logic | 1 cycle |
| Shift | 1 cycle |
| Compare | 1 cycle |

---

# 11. Resource Estimate

Artix-7

| Resource | Estimate |
|-----------|----------|
| LUT | 150~300 |
| FF | 0 |
| DSP | 0 |

Implementation shall use LUT logic only.

DSP48 shall be reserved for multiplier.

---

# 12. Verification Plan

## Test 1

Addition

```
5 + 10

↓

15
```

---

## Test 2

Subtraction

```
20 - 5

↓

15
```

---

## Test 3

Overflow

```
FFFFFFFF

+

1

↓

00000000
```

---

## Test 4

Logical Operations

```
AND

OR

XOR
```

Compare against software model.

---

## Test 5

Shift

```
SLL

SRL

SRA
```

Check

- Shift by 0
- Shift by 31
- Random shift

---

## Test 6

Signed Compare

```
-1 < 1

↓

TRUE
```

---

## Test 7

Unsigned Compare

```
FFFFFFFF

<

1

↓

FALSE
```

---

## Test 8

Random Regression

Generate

100000

random operand pairs.

Compare with C reference model.

---

# 13. Assertions

```systemverilog
assert(alu_op <= ALU_COPY_B);
```

---

```systemverilog
assert((alu_op==ALU_ADD) |-> result==(op_a+op_b));
```

---

```systemverilog
assert((alu_op==ALU_SUB) |-> result==(op_a-op_b));
```

---

```systemverilog
assert((alu_op==ALU_AND) |-> result==(op_a&op_b));
```

---

```systemverilog
assert((alu_op==ALU_OR) |-> result==(op_a|op_b));
```

---

# 14. Future Extensions

Support for:

- RV32B Bit Manipulation
  - CLZ
  - CTZ
  - CPOP
  - ROR
  - ROL
  - ORC.B
  - REV8

- Custom Instructions

- SIMD ALU

---

# 15. Design Decisions

| Item | Decision |
|------|----------|
| Architecture | Combinational |
| Pipeline Stage | Execute |
| Width | 32-bit |
| Arithmetic Overflow | Ignored |
| Multiply | Dedicated Multiplier |
| Divide | Dedicated Divider |
| Floating Point | External FPU |
| DSP Usage | None |
| Shift Implementation | Barrel Shifter |
| Compare | Dedicated Comparator |
| Branch Compare | Integrated |