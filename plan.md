Updated todo list

Tôi đã có đủ thông tin. Để tôi viết plan chi tiết. 

Created memory file [](file:///c%3A/Users/ngoch/AppData/Roaming/Code/User/workspaceStorage/990acf63a0221c9fd33620981cf5957c/GitHub.copilot-chat/memory-tool/memories/ZGZiZTExZjctNjNmMS00Nzk2LTk4MzYtMzgyODE2YmY3Y2E3/plan.md)

Tôi đã có đầy đủ thông tin. Đây là plan tổng thể:

---

## Plan: RISC-V SoC "RVPRO32" trên Arty A7-100T

**TL;DR:** Tự thiết kế từ đầu một RISC-V 32-bit SoC đầy đủ tính năng trong Verilog, verify bằng Verilator + riscv-formal, nạp lên FPGA qua Vivado. Đi kèm là tự viết toàn bộ software stack: assembler, linker, compiler C (subset), và một Unix-like kernel lấy cảm hứng từ Linux/xv6 — không phụ thuộc GCC hay Linux thật ở giai đoạn cuối. Học toàn bộ CPU pipeline, cache, MMU, FPU, privilege modes, SoC interconnect, compiler construction, và OS construction.

**3 Track song song:**

| Track | Nội dung | Ngôn ngữ |
|---|---|---|
| **A — Hardware** | CPU core RVPRO32 + SoC + peripherals | Verilog |
| **B — Toolchain** | RVPRO-AS (assembler) → RVPRO-LD (linker) → RVPRO-CC (C compiler) | C |
| **C — OS** | RVPRO-OS: kernel Unix-like tự viết (process, VM, syscall, FS, shell) | Subset-C (biên dịch bằng RVPRO-CC) |

> ⚠️ **Đánh giá thực tế**: xem mục "Đánh giá thực tế & Chiến lược Bootstrap" ngay bên dưới trước khi bắt đầu — giải thích tại sao mốc thời gian tổng thể sẽ dài hơn 6-12 tháng ban đầu, và chiến lược "bootstrap" giúp không bị tắc nghẽn ngay từ đầu.

---

### Spec CPU: "RVPRO32"

| Thành phần | Chi tiết |
|---|---|
| **ISA** | `RV32IMAFC_Zicsr_Zifencei_Zba_Zbb_Zbs` |
| **Pipeline** | 5-stage in-order (IF → ID → EX → MEM → WB), full forwarding |
| **Branch prediction** | BTB 64-entry + BHT 256-entry 2-bit + RAS 8-entry |
| **Privilege modes** | M / S / U (RISC-V Privileged Spec v1.12) |
| **MMU** | Sv32: ITLB 8-entry + DTLB 16-entry + hardware page table walker |
| **I-cache** | 16KB, 4-way set-associative, 32-byte lines, LRU |
| **D-cache** | 16KB, 4-way SA, write-back, write-allocate, MSHR |
| **FPU** | IEEE 754-2008 single-precision, FMA (dùng DSP48E1) |
| **Multiply** | 32×32→64-bit, 2-cycle pipelined, DSP48E1 |
| **Divide** | 32-bit iterative ~32 cycles |
| **Tại sao RV32?** | RV32 Linux được hỗ trợ (kernel 5.11+, Sv32), tiết kiệm tài nguyên hơn RV64 — phù hợp để tự viết toàn bộ |
| **Extensions loại trừ** | D (double precision — quá tốn DSP), V (vector — quá lớn) |

**SoC Peripherals:**
- UART 16550 ×2, GPIO 32-bit có IRQ, SPI/QSPI ×2, I2C ×2, PWM ×4
- CLINT (mtime/mtimecmp), PLIC (32 nguồn, 8 mức ưu tiên)
- Ethernet 10/100 (Xilinx Tri-Mode MAC → onboard PHY)
- JTAG Debug Module (RISC-V Debug Spec 0.13.2 → OpenOCD + GDB)

**Memory Map:**

| Địa chỉ | Kích thước | Nội dung |
|---|---|---|
| `0x0000_0000` | 64KB | Boot ROM (BRAM) |
| `0x0200_0000` | — | CLINT |
| `0x0C00_0000` | — | PLIC |
| `0x1000_x000` | 4KB each | UART0/1, GPIO, SPI, I2C, PWM, Ethernet |
| `0x2000_0000` | 256KB | On-chip SRAM (BRAM) |
| `0x8000_0000` | 256MB | DDR3L (qua Xilinx MIG) |

---

### ⚠️ Đánh giá thực tế & Chiến lược Bootstrap

**Về "tự viết toolchain từ đầu":** Hoàn toàn khả thi và là một trong những cách học compiler tốt nhất (nhiều dự án nổi tiếng làm điều này để học: chibicc, 9cc, shecc, SubC...). Phạm vi thực tế: một compiler cho **subset C** đủ dùng để viết OS + firmware (không cần hỗ trợ 100% chuẩn C11), không dùng LLVM/GCC làm backend.

**Về "tự viết Linux từ đầu":** Linux kernel thật có ~30+ triệu dòng code, hàng chục nghìn contributor, hàng chục nghìn người-năm phát triển — viết lại toàn bộ là bất khả thi cho một người dù làm full-time nhiều năm. Mục tiêu thực tế và **vẫn cực kỳ giá trị để học toàn diện**: viết một **Unix-like teaching kernel nguyên bản** (không copy code Linux/xv6) với kiến trúc lấy cảm hứng từ Linux/xv6 — process, virtual memory, syscall, filesystem, device driver, shell. Đây chính xác là cách MIT dạy môn hệ điều hành (khóa 6.S081) bằng xv6-riscv. Kernel này gọi là **RVPRO-OS**.

**Vấn đề "con gà và quả trứng" (bootstrapping):** Để verify RTL (Track A) cần chương trình test (assembly/C). Nếu chưa có toolchain tự viết ngay từ đầu, Track A sẽ bị tắc nghẽn hàng tháng trước khi chạy được dòng code đầu tiên. Chiến lược 3 bước:
1. **Bootstrap tạm thời**: dùng `riscv32-unknown-elf-gcc/as/ld` (GNU toolchain có sẵn) làm **oracle tham khảo** để verify RTL sớm (Phase 0-4) và đối chiếu encoding khi debug RVPRO-AS/RVPRO-CC sau này. Đây là thực hành chuẩn kể cả trong công nghiệp (dùng golden model để so sánh).
2. **Xây song song**: bắt đầu viết RVPRO-AS (Track B) từ tháng 1, song song Track A. Assembler xong trước → dùng thay GNU as để assemble riscv-arch-test.
3. **Chuyển giao dần**: khi RVPRO-CC đủ mạnh (biên dịch được C có struct/pointer/function), toàn bộ software từ đó về sau (BSP, RVPRO-OS) dùng RVPRO-CC — GNU GCC chỉ còn là công cụ đối chiếu khi debug, không còn là dependency bắt buộc.

**Mốc thời gian điều chỉnh thực tế:** Với phạm vi đầy đủ (Hardware + tự viết Assembler + Linker + Compiler + OS Unix-like), tổng thời gian thực tế nên tính là **18-30 tháng** làm việc bán thời gian (không phải 6-12 tháng). Plan chia theo **Năm 1** (Hardware hoàn chỉnh + Toolchain hoàn chỉnh + OS đến mức boot process/syscall/shell) và **Năm 2+** (OS mở rộng, tối ưu, polish). Không có deadline cứng — tiến độ phụ thuộc thời gian bạn đầu tư mỗi tuần.

---

### Master Timeline (Năm 1) — 3 Track song song

| Tháng | Track A (Hardware) | Track B (Toolchain) | Track C (OS) |
|---|---|---|---|
| 1 | Phase 0-1: RV32I pipeline | T-B0 → T-B1: bắt đầu RVPRO-AS | — |
| 2 | Phase 2-3: M/C ext, CSR/Privilege | T-B1 tiếp: RVPRO-AS cho M/C | — |
| 3 | Phase 4-5: A ext, Sv32 MMU | T-B2: RVPRO-LD | — |
| 4 | Phase 6-7: FPU, Bitmanip | T-B3 bắt đầu: RVPRO-CC (lexer/parser) | — |
| 5 | Phase 8-9: Cache, Branch predict | T-B3 tiếp: control flow, function call | — |
| 6 | Phase 10-12: AXI4, Peripherals, DDR3 | T-B3 hoàn thiện: struct/pointer/array | C0: chuẩn bị OS |
| 7 | Phase 13-14: Debug module, Boot ROM | Regression suite + thử self-hosting | C1-C2: Boot, trap, physical allocator |
| 8 | Phase 15: Bare-metal C (dùng RVPRO-CC) | Bugfix theo phản hồi từ Track C | C3-C4: Sv32 VM, process management |
| 9 | Phase 16: Mini-kernel demo | — | C4-C5: scheduler, syscall interface |
| 10 | Phase 17 bắt đầu: OS integration | — | C6: ELF loader, chuyển U-mode |
| 11 | Tích hợp + FPGA validation | — | C7-C8: filesystem, device driver |
| 12 | Phase 18: verification, timing closure | — | C9: shell, user program |

**Năm 2 (nếu tiếp tục):** C10 mở rộng (priority scheduler, networking, swap), tối ưu hiệu năng toàn hệ thống, viết thêm ứng dụng demo, polish.

---

### Track A: Hardware (RTL) — Chi tiết từng Phase

#### Phase 0 — Environment Setup (Tuần 1–2)
1. Cài `riscv32-unknown-elf-gcc` toolchain (từ riscv-gnu-toolchain) — **chỉ dùng làm oracle/bootstrap tạm thời**, xem chiến lược bootstrap ở trên
2. Cài Verilator 5.x + GTKWave
3. Tạo Vivado project cho XC7A100TCSG324-1
4. Cài OpenOCD (RISC-V fork)
5. Đọc: RISC-V Unprivileged Spec + Privileged Spec (PDF chính thức) + RISC-V ELF psABI spec (cần cho Track B)
6. Tạo cấu trúc thư mục: `rtl/`, `sim/`, `sw/`, `fpga/`, `verif/`, `toolchain/{as,ld,cc}/`, `os/`
7. **[Track B song song]** Đọc lý thuyết lexer/parser/codegen cơ bản để chuẩn bị viết RVPRO-AS

#### Phase 1 — RV32I 5-stage Pipeline (Tháng 1)
1. Module `if_stage.v`: PC, instruction fetch từ BRAM
2. Module `id_stage.v`: decode, register file (x0–x31)
3. Module `ex_stage.v`: ALU, branch condition
4. Module `mem_stage.v`: load/store
5. Module `wb_stage.v`: writeback
6. `hazard_unit.v`: stall + data forwarding (EX→EX, MEM→EX)
7. Verilator testbench: compile C → riscv32 elf → run
8. Pass **riscv-arch-test rv32i**

#### Phase 2 — M Extension + C Extension (Tháng 1–2)
1. `multiplier.v`: 32×32→64 dùng DSP48E1, 2-cycle pipelined
2. `divider.v`: restoring division, 32-cycle iterative
3. `c_decoder.v`: pre-decode 16-bit → 32-bit trước IF/ID boundary
4. Pass riscv-arch-test rv32im, rv32ic

#### Phase 3 — Zicsr + M/S/U Privilege + Exceptions (Tháng 2)
1. `csr_regfile.v`: toàn bộ CSRs (mstatus, mepc, mcause, mtvec, sstatus, sepc, stvec, satp,...)
2. Exception handling: illegal instruction, misaligned, ecall, ebreak
3. M-mode → S-mode → U-mode transitions
4. `clint.v`: mtime, mtimecmp, msip
5. Pass privilege compliance tests

#### Phase 4 — A Extension + Zifencei (Tháng 2–3)
1. LR.W / SC.W với reservation set
2. AMO: AMOADD, AMOSWAP, AMOAND, AMOOR, AMOXOR, AMOMAX, AMOMIN
3. FENCE.I: flush pipeline + invalidate I-cache
4. Pass riscv-arch-test rv32ia

#### Phase 5 — Sv32 MMU (Tháng 3) *(phụ thuộc vào Phase 3)*
1. `ptw.v`: hardware page table walker (2-level Sv32)
2. `itlb.v`: 8-entry fully-associative, ASID-tagged
3. `dtlb.v`: 16-entry fully-associative
4. SFENCE.VMA: flush TLB
5. Page fault exceptions (instruction/load/store)

#### Phase 6 — F Extension FPU (Tháng 3–4) *(song song với Phase 5)*
1. FP register file `fregfile.v` (f0–f31, 32-bit)
2. `fpu.v`: FADD, FSUB, FMUL, FDIV, FSQRT, FMA (dùng DSP48E1)
3. Rounding modes: RNE, RTZ, RDN, RUP, RMM
4. FCVT.W.S, FCVT.S.W, FMV, FEQ, FLT, FLE
5. Pass riscv-arch-test rv32if

#### Phase 7 — Zba/Zbb/Zbs Bit Manipulation (Tháng 4) *(song song, nhẹ)*
- Zba: SH1ADD, SH2ADD, SH3ADD
- Zbb: CLZ, CTZ, CPOP, MAX/MIN, ORC.B, REV8, ROL, ROR, ZEXT.H
- Zbs: BCLR, BEXT, BINV, BSET

#### Phase 8 — L1 I/D Caches (Tháng 4–5) *(phụ thuộc vào Phase 5)*
1. `icache.v`: 16KB 4-way SA, VIPT, LRU, AXI4 master
2. `dcache.v`: 16KB 4-way SA, write-back, MSHR 2 entries, AXI4 master
3. Cache invalidation khi TLB flush (SFENCE.VMA)
4. Verilator cache sim: hit rate, miss rate trace

#### Phase 9 — Branch Prediction (Tháng 5) *(song song với Phase 8)*
1. `btb.v`: 64-entry direct-mapped Branch Target Buffer
2. `bht.v`: 256-entry 2-bit saturating counter
3. `ras.v`: 8-entry Return Address Stack (JAL/JALR)
4. Flush pipeline khi misprediction, track accuracy

#### Phase 10 — AXI4 SoC Interconnect (Tháng 5)
1. `axi4_xbar.v`: crossbar (2 master: CPU I$ + D$; N slaves)
2. `axi4_to_axilite.v`: bridge cho peripherals
3. `addr_decoder.v`: routing theo memory map

#### Phase 11 — Peripheral IPs (Tháng 5–6) *(song song Phase 10)*
1. `uart16550.v`: 16550-compatible, TX/RX FIFO, baud gen
2. `gpio.v`: 32-bit I/O, IRQ edge detect
3. `spi_master.v`: QSPI cho flash + general purpose
4. `i2c_master.v` x2
5. `pwm.v` x4: 16-bit counter, prescaler
6. `plic.v`: 32 sources, 8 priorities, claim/complete
7. Ethernet: integrate Xilinx **Tri-Mode Ethernet MAC IP** + MDIO

#### Phase 12 — DDR3 via Xilinx MIG (Tháng 5–6) *(song song Phase 11)*
1. Tạo Xilinx MIG IP trong Vivado cho DDR3L (256MB, 16-bit)
2. AXI4 slave wrapper cho MIG
3. Kết nối vào SoC crossbar
4. Chạy MIG self-test qua Vivado ILA

#### Phase 13 — JTAG Debug Module (Tháng 6)
1. `dtm.v`: Debug Transport Module qua JTAG TAP (IEEE 1149.1)
2. `dm.v`: Debug Module (halt/resume, abstract commands, program buffer)
3. Kết nối GDB → OpenOCD → JTAG → DM
4. Test: GDB breakpoint, register read/write, memory dump

#### Phase 14 — Boot ROM + Bootloader (Tháng 6)
1. Boot ROM 64KB trong BRAM: địa chỉ `0x0000_0000`
2. FSBL (First Stage Bootloader): init DDR3, đọc SPI flash, copy → DDR3, jump
3. UART boot mode: nhận binary qua xmodem (để debug nhanh không cần flash)
4. Tích hợp **OpenSBI** (M-mode firmware chuẩn cho Linux)

#### Phase 15 — Bare-Metal C (Tháng 7)
1. Linker script theo memory map (viết cho cả GNU ld lẫn RVPRO-LD)
2. `crt0.S`: startup code (stack init, BSS clear, call main)
3. BSP drivers: UART print, GPIO blink, timer delay
4. Build bằng `riscv32-unknown-elf-gcc` (nếu RVPRO-CC chưa xong) hoặc **RVPRO-CC** (nếu đã đủ mạnh — xem Track B, mốc T-B3), nạp qua UART/JTAG
5. Demo: HelloWorld UART, LED blink, interrupt-driven timer
6. Milestone đối chiếu: build cùng chương trình bằng cả GNU gcc và RVPRO-CC, so sánh hành vi chạy trên board — giống nhau nghĩa là RVPRO-CC đã sẵn sàng thay thế hoàn toàn

#### Phase 16 — RVPRO-OS v0: Mini-kernel cooperative/preemptive (Tháng 7–8)
> Thay vì port FreeRTOS thật, đây là bước đầu của Track C (RVPRO-OS) — chi tiết đầy đủ ở mục "Track C: RVPRO-OS" bên dưới. Tương đương khái niệm FreeRTOS (task, scheduler, semaphore) nhưng code 100% tự viết.
1. Context switch tự viết (`swtch.S`, dùng M-mode traps)
2. Scheduler round-robin dùng CLINT mtime làm tick
3. Demo: 3 task tự viết (LED, UART echo, timer print) chạy preemptive
4. Test preemption + semaphore tự cài đặt

#### Phase 17 — RVPRO-OS v1: Full Unix-like kernel (Tháng 8 – Năm 2)
> Thay thế việc port Linux thật — chi tiết đầy đủ (C0-C10) ở mục "Track C: RVPRO-OS" bên dưới. Đây là phần dài nhất của dự án, thường kéo sang năm thứ 2 nếu làm đầy đủ filesystem + nhiều user program.
1. Virtual memory Sv32 (dùng MMU Phase 5) + process management + syscall
2. ELF loader (đọc ELF do RVPRO-LD tạo ra)
3. Filesystem tối giản trên RAM disk → nâng cấp SPI flash
4. Driver: UART console, timer, GPIO, PLIC
5. Shell tự viết + vài user program, biên dịch bằng RVPRO-CC
6. Boot sequence: SPI Flash → RVPRO bootloader → RVPRO-OS kernel → shell

#### Phase 18 — Verification & Optimization (Năm 1 cuối – Năm 2 đầu)
1. **riscv-arch-test**: full compliance (rv32i/m/a/c/f + privilege) — assemble bằng RVPRO-AS
2. **riscv-formal**: ISA formal verification (bmc + k-induction)
3. **CoreMark**: benchmark hiệu năng, tối ưu CPI (biên dịch bằng RVPRO-CC, so sánh với bản GCC)
4. Vivado timing closure: target ≥ 80MHz trên Artix-7 (sau khi có caches)
5. Vivado ILA: trace pipeline, cache miss, TLB miss trên hardware
6. Power analysis: Vivado Power Estimator
7. Regression suite Track B + Track C: chạy toàn bộ test corpus compiler + OS sau mỗi thay đổi RTL

---

### Track B: RVPRO-Toolchain (Assembler + Linker + Compiler tự viết)

**Nguyên tắc thiết kế:** viết bằng C (để hướng tới self-hosting — RVPRO-CC tự biên dịch được chính RVPRO-AS/LD). GNU binutils/gcc chỉ dùng để **đối chiếu** (diff encoding, diff hành vi), không phải dependency.

#### T-B0 — Chuẩn bị (song song Phase 0 Hardware, Tuần 1–2)
1. Đọc: RISC-V ELF psABI spec, RISC-V Assembly Programmer's Manual
2. Đọc lý thuyết lexer/parser (recursive descent)
3. Tạo cấu trúc `toolchain/as/`, `toolchain/ld/`, `toolchain/cc/`

#### T-B1 — RVPRO-AS: Assembler (song song Phase 1–2 Hardware, Tháng 1–2)
1. Lexer: token hóa mnemonic, register (x0-x31/tên ABI), immediate, label, directive
2. Parser 2-pass: pass 1 xây symbol table (label → offset), pass 2 encode → machine code
3. Bảng encode instruction: bắt đầu RV32I, mở rộng dần M/A/C theo tiến độ Track A
4. Directives tối thiểu: `.text .data .word .byte .align .global .equ .string`
5. Output: bắt đầu bằng raw binary/hex (`$readmemh` cho testbench) → nâng cấp thành ELF relocatable `.o` (section header, symtab, relocation entries)
6. Relocation cần hỗ trợ: `R_RISCV_HI20`, `R_RISCV_LO12_I/S`, `R_RISCV_BRANCH`, `R_RISCV_JAL`, `R_RISCV_CALL`, `R_RISCV_32`

**Cách test:**
- So sánh hex encoding từng lệnh với `riscv32-unknown-elf-as` (diff `objdump -d`) khi thêm nhóm lệnh mới
- Assemble file riscv-arch-test, chạy trên Verilator, so sánh signature với reference
- Regression script `test_as.sh` chạy lại toàn bộ test case sau mỗi commit

#### T-B2 — RVPRO-LD: Linker (Tháng 2–3, sau T-B1)
1. Parser ELF relocatable `.o` (section header, symtab)
2. Section merging theo linker script cú pháp riêng (đơn giản hơn GNU ld script)
3. Symbol resolution: bảng symbol toàn cục, phát hiện undefined/multiple definition
4. Áp dụng relocation (offset PC-relative, HI20/LO12 split)
5. Output: ELF executable tĩnh (không dynamic linking), entry point rõ ràng

**Cách test:**
- Link nhiều file `.o` nhỏ (main.o + lib.o), so sánh disassembly với GNU ld
- Chạy chương trình đã link trên Verilator, kiểm tra hành vi
- Dùng `readelf` (GNU, chỉ để debug) đối chiếu cấu trúc ELF output

#### T-B3 — RVPRO-CC: Compiler C subset (Tháng 3–6, song song Phase 5–9 Hardware)
**Phạm vi ngôn ngữ** (đủ viết OS + firmware, không cần full C11):
- Kiểu: `int char pointer array[1D/2D] struct enum` (union/long long thêm sau nếu cần)
- Control flow: `if/else while for do-while switch break continue return`
- Function: khai báo/định nghĩa, đệ quy, con trỏ hàm (varargs như `printf` làm sau cùng)
- Operator: đầy đủ arithmetic/logic/bitwise/so sánh, `* & -> []`
- Preprocessor tối giản: `#include #define` (macro object-like), `#ifdef` cơ bản
- **Bỏ qua ban đầu:** float trong compiler, VLA, bit-field, goto (thêm sau nếu cần)

**Kiến trúc:**
1. Lexer (tái dùng ý tưởng từ RVPRO-AS)
2. Parser recursive-descent → AST (expression theo precedence climbing)
3. Semantic pass: symbol table theo scope, type checking cơ bản
4. Codegen giai đoạn 1: naive stack-machine — ưu tiên đúng trước khi tối ưu
5. Codegen giai đoạn 2 (sau khi chạy đúng): linear-scan register allocation
6. Emit: sinh file `.s` rồi gọi RVPRO-AS xử lý (tách rời để dễ debug từng tầng)

**Cách test (quan trọng nhất — dễ có bug logic nhất):**
- Bộ test tăng dần độ khó, mỗi test có giá trị expected rõ ràng:
  1. `return 42;` → kiểm tra exit code/return value
  2. Arithmetic + operator precedence
  3. `if/else`, loop (`for/while`)
  4. Function call, đệ quy (fibonacci, factorial)
  5. Pointer, array, con trỏ hàm
  6. Struct, nested struct
  7. Chương trình nhỏ hoàn chỉnh (linked list, bubble sort)
- Mỗi test: compile bằng RVPRO-CC → chạy trên Verilator → in kết quả qua UART → script so sánh giá trị expected (tự động hóa `run_cc_tests.sh`, fail nếu có test đỏ)
- Khi nghi ngờ compiler sai logic: compile cùng source bằng GNU gcc, chạy trên host, so sánh **hành vi/output** (không so sánh assembly) để cô lập bug
- **Milestone self-hosting:** dùng RVPRO-CC biên dịch lại chính source RVPRO-AS (nếu viết bằng subset C hỗ trợ) — chạy đúng chứng tỏ compiler đã trưởng thành

---

### Track C: RVPRO-OS — Unix-like Kernel tự viết

> Lấy cảm hứng kiến trúc từ Linux/xv6, **code 100% tự viết** (không copy nguồn Linux/xv6). Phần dự án lớn và dài nhất, phụ thuộc Track A Phase 5 (MMU) và Track B T-B3 (compiler dùng được cơ bản).

#### C0 — Chuẩn bị (Tháng 6, sau khi Phase 5 + T-B3 cơ bản xong)
1. Đọc **"xv6: a simple, Unix-like teaching operating system" (MIT 6.S081)** để hiểu kiến trúc (chỉ đọc để hiểu, không copy code)
2. Định nghĩa syscall ABI riêng: số hiệu syscall, tham số qua `a0-a7`, gọi qua `ecall`
3. Tạo cấu trúc `os/{boot,mm,proc,fs,drivers,user}/`

#### C1 — Boot & Trap (Tháng 7)
1. `entry.S`: thiết lập stack ban đầu, nhảy vào `kmain()`
2. `trap.c`: xử lý `ecall` (syscall), interrupt (timer/external qua PLIC), exception (page fault, illegal instruction)

#### C2 — Physical Memory Allocator (Tháng 7)
1. Free-list allocator quản lý trang 4KB trong vùng DDR3 dành cho kernel
2. Test: alloc/free liên tục, kiểm tra không cấp phát trùng trang

#### C3 — Virtual Memory (Sv32) (Tháng 8)
1. Tạo/quản lý page table 2-level, hàm `map_page()/unmap_page()`
2. Tách kernel space (địa chỉ cao) và user space (địa chỉ thấp)
3. Test: map page, đọc lại PTE qua PTW hardware (Phase 5), assert đúng physical address

#### C4 — Process Management (Tháng 8–9)
1. `struct proc`: pid, state, trapframe, page table riêng, kernel stack riêng
2. `swtch.S`: context switch (lưu/khôi phục callee-saved registers)
3. Scheduler round-robin đơn giản (nâng cấp priority-based sau)
4. Test: 2 process in xen kẽ ra UART → xác nhận context switch đúng

#### C5 — Syscall Interface (Tháng 9)
1. `exit, wait, spawn (hoặc fork/exec), read, write, getpid, sbrk`
2. Test: user program gọi từng syscall, kiểm tra kernel xử lý đúng

#### C6 — User Mode + ELF Loader (Tháng 9–10)
1. Parse ELF do RVPRO-LD tạo ra, load segment vào page table user process
2. Setup user stack (argc/argv), chuyển sang U-mode bằng `sret`
3. Test: chạy user program hello world trong U-mode, xác nhận cô lập với kernel (truy cập kernel memory → page fault)

#### C7 — Filesystem tối giản (Tháng 10–11)
1. Bắt đầu: RAM disk (mảng cố định trong DDR3) + FS đơn giản (inode-based hoặc flat file table)
2. Nâng cấp: driver SPI flash thật để đọc/ghi block persistent
3. Test: tạo file, ghi, đọc lại, so sánh nội dung; reset board, kiểm tra dữ liệu trên flash còn nguyên

#### C8 — Device Drivers (song song C7)
1. UART console driver (dùng làm tty, buffered input/output)
2. Timer driver (CLINT) cho scheduler tick
3. GPIO driver

#### C9 — Shell & User Programs (Tháng 11–12)
1. Shell tối giản tự viết (parse lệnh, `spawn`/`fork+exec`), biên dịch bằng RVPRO-CC
2. Vài lệnh cơ bản: `ls cat echo ps`
3. Test: chạy nhiều lệnh liên tiếp, pipe đơn giản (stretch)

#### C10 — (Stretch, Năm 2) Mở rộng
- Priority scheduler, swap, networking cơ bản (nếu Ethernet driver Phase 11 xong), SMP (stretch rất xa)

**Cách test tổng thể cho Track C:**
1. Test từng subsystem độc lập trên Verilator trước khi tích hợp (allocator, page table, context switch)
2. Test tích hợp: boot → shell, chạy nhiều user program đồng thời
3. Test lỗi cố ý: user program truy cập địa chỉ không hợp lệ → xác nhận kernel bắt page fault và kill process gracefully
4. Đối chiếu hành vi: khi nghi ngờ bug logic OS, chạy kiến trúc tương tự trên **xv6-riscv thật + QEMU** để so sánh hành vi mong đợi (chỉ tham khảo hành vi, không copy code)
5. Test trên FPGA thật ở cuối mỗi milestone lớn (C4, C6, C9) — Verilator không bắt được lỗi timing/hardware-specific

---

### Relevant Files / Thư mục Đề xuất
```
rtl/
  core/          — pipeline stages, hazard, CSR, FPU, mul/div
  mmu/           — PTW, ITLB, DTLB
  cache/         — icache, dcache
  soc/           — AXI4 xbar, peripherals, debug module
  fpga/          — top-level wrapper, MIG, clocking
sim/
  verilator/     — testbenches per module
  riscv-arch-test/
  riscv-formal/
toolchain/                — Track B: RVPRO-Toolchain (tự viết bằng C)
  as/                      — RVPRO-AS: lexer, parser, encoder, ELF .o writer
  ld/                      — RVPRO-LD: symbol resolution, relocation, ELF writer
  cc/                      — RVPRO-CC: lexer, parser/AST, semantic, codegen
  tests/                   — regression test corpus (as/cc), so sánh với GNU oracle
os/                        — Track C: RVPRO-OS (Unix-like kernel tự viết)
  boot/                    — entry.S, trap.c
  mm/                      — physical allocator, Sv32 page table
  proc/                    — PCB, swtch.S, scheduler, syscall
  fs/                      — RAM disk / SPI flash filesystem
  drivers/                 — UART, timer, GPIO, PLIC
  user/                    — shell, user program (biên dịch bằng RVPRO-CC)
sw/
  bootloader/    — FSBL, crt0, linker scripts
  bsp/           — bare-metal drivers (Phase 15)
fpga/
  constraints/   — XDC pin assignments (Arty A7)
  vivado_project/
```

---

### Verification Steps
**Track A (Hardware):**
1. Mỗi module: Verilator unit test + GTKWave waveform
2. `make sim` chạy toàn bộ riscv-arch-test (tất cả extensions), assemble bằng RVPRO-AS khi sẵn sàng
3. riscv-formal formal verification cho core instructions
4. Vivado synthesis sau mỗi phase: kiểm tra LUT/FF/BRAM/DSP usage
5. FPGA hardware: UART "Hello World" → RVPRO-OS mini-kernel demo → RVPRO-OS full boot → shell
6. CoreMark score đo đạc cuối dự án (biên dịch bằng RVPRO-CC)

**Track B (Toolchain):**
7. So sánh encoding (assembler) và ELF layout (linker) với GNU binutils làm oracle
8. Regression suite test corpus compiler chạy sau mỗi thay đổi (`run_cc_tests.sh`)
9. Milestone self-hosting: RVPRO-CC tự biên dịch được RVPRO-AS

**Track C (OS):**
10. Unit test từng subsystem kernel (allocator, page table, context switch) trên Verilator
11. Test lỗi cố ý (page fault, invalid syscall) — kernel phải xử lý gracefully, không treo máy
12. Đối chiếu hành vi với xv6-riscv/QEMU khi nghi ngờ bug logic

---

### Decisions & Scope
- **RV32 thay vì RV64**: tiết kiệm ~30% LUT, dễ debug hơn khi tự viết compiler/OS, Sv32 đơn giản hơn Sv39 để tự cài đặt
- **Không có D extension**: double-precision FPU tốn quá nhiều DSP48; có thể add sau nếu muốn
- **Không có V extension**: vector tốn hàng chục nghìn LUT, không phù hợp A7-100T cho dự án tự viết
- **AXI4 interconnect**: chuẩn industry, tái sử dụng được với Xilinx IPs (MIG, Ethernet MAC)
- **Ước tính tài nguyên**: CPU core + caches ~30–45K LUT, MIG ~10K, peripherals ~10K, tổng ~55K / 101K LUT — an toàn
- **Toolchain tự viết bằng C** (không phải Python/Rust) để hướng tới self-hosting (RVPRO-CC tự biên dịch được RVPRO-AS/LD)
- **RVPRO-OS không phải Linux thật**: kiến trúc lấy cảm hứng Linux/xv6, code 100% nguyên bản — mục tiêu học, không phải tương thích Linux ABI/driver ecosystem
- **GNU toolchain (gcc/as/ld) chỉ là oracle bootstrap tạm thời**: dùng để verify sớm và đối chiếu debug, không phải dependency lâu dài

### Further Considerations
1. **Bắt đầu từ đâu?** Recommend: Phase 0 + 1 (Track A) song song T-B0 + T-B1 (Track B) → mốc tuần 3: RTL chạy chương trình assembly tự viết trên Verilator
2. **Có cần viết AXI4 từ đầu không?** Có thể dùng Xilinx AXI Interconnect IP từ Vivado IP Catalog để tiết kiệm thời gian, focus vào CPU core + Track B/C
3. **Vitis dùng để làm gì?** Hữu ích cho giai đoạn bare-metal debugging ban đầu (Phase 15) khi RVPRO-CC chưa sẵn sàng; không cần thiết một khi Track B/C tự chủ hoàn toàn
4. **Mốc thời gian thực tế**: 6-12 tháng ban đầu chỉ đủ cho Hardware hoàn chỉnh + Toolchain hoàn chỉnh + OS đến mức C4/C5 (process + syscall). Full filesystem + shell + user program (C7-C9) thường kéo sang năm thứ 2. Đây là điều bình thường với một dự án học tập ở độ sâu này — cứ tiếp tục theo tốc độ của bạn, không cần deadline cứng.

---

Updated todo list

Dựa trên plan hiện tại (đã rất đầy đủ với Track A/B/C), đây là những gì có thể **bổ sung thêm** — chia theo mức độ ưu tiên và giá trị học tập:

## 1. Hardware (Track A) — thêm tính năng ISA/vi kiến trúc

| Bổ sung | Giá trị học | Độ khó |
|---|---|---|
| **PMP (Physical Memory Protection)** | Cơ chế bảo vệ vùng nhớ chuẩn RISC-V, quan trọng cho security — nên thêm vào Phase 3 luôn vì không tốn nhiều công | Trung bình |
| **Zicntr/Zihpm (Performance counters)** | `mcycle`, `minstret`, hpmcounters — cần để đo hiệu năng thật (CPI, cache hit rate) thay vì chỉ đoán | Thấp |
| **DMA controller** | Peripheral-to-memory transfer không cần CPU — học kiến trúc bus master độc lập | Trung bình |
| **D extension (double-precision FPU)** | Đã loại trừ ban đầu, có thể thêm ở "Năm 2" nếu còn dư DSP48 | Cao |
| **Custom instruction (opcode custom-0/1)** | Tự thiết kế 1 lệnh accelerator riêng (VD: CRC32, AES round) — học cách mở rộng ISA đúng chuẩn | Trung bình |
| **XADC driver** | Artix-7 có ADC on-chip sẵn — đọc nhiệt độ/điện áp FPGA, gần như free feature | Thấp |
| **2nd core / SMP (stretch rất xa)** | Cache coherency (MESI đơn giản), spinlock — mở ra chủ đề multiprocessor | Rất cao |
| **Superscalar/OoO (v2 core, Năm 2+)** | Nếu muốn học kiến trúc CPU cao cấp hơn 5-stage in-order | Rất cao |

## 2. Verification — nâng cấp đáng làm nhất

- **Spike co-simulation (lock-step)**: chạy song song RVPRO32 RTL và [Spike](https://github.com/riscv-software-src/riscv-isa-sim) (ISA simulator chính thức của RISC-V), so sánh từng instruction retire (PC, giá trị ghi register) — đây là kỹ thuật **chuẩn công nghiệp thật** để verify CPU, mạnh hơn nhiều so với chỉ chạy riscv-arch-test
- **Code coverage** (`verilator --coverage`): đo dòng nào/toggle nào chưa test tới
- **Random instruction fuzzing**: viết generator sinh chương trình ngẫu nhiên hợp lệ, so sánh kết quả với Spike — bắt được bug mà test case viết tay không nghĩ tới
- **CI pipeline** (GitHub Actions): tự động chạy regression Track A+B+C mỗi lần commit

## 3. Toolchain (Track B) — phần còn thiếu quan trọng

- **RVPRO-LIBC**: mini libc tự viết (malloc/free, string.h, printf/scanf subset) — **cần thiết** để Track C (OS) có user program dùng được, nên thêm ngay sau T-B3
- **RVPRO-OBJDUMP**: disassembler riêng để debug (thay vì phụ thuộc GNU objdump)
- **Compiler fuzzing**: dùng csmith-style random C generator để tìm miscompilation

## 4. OS (Track C) — mở rộng sau C9

- **Networking stack tối giản**: tự viết ARP/IP/UDP/ICMP (ping) trên Ethernet MAC đã có ở Phase 11 — rất đáng làm vì tận dụng hardware đã xây
- **Pipe/redirect trong shell**: nâng cấp C9 từ "vài lệnh" lên shell thực sự dùng được
- **RTC + Watchdog peripheral**: thêm driver, dùng cho power-loss recovery

## 5. Capstone Demo (mục tiêu cuối để "khoe" — nhiều dự án RISC-V hobby hay làm)

- Chạy **DOOM** hoặc game text-mode trên RVPRO-OS (capstone phổ biến trong giới làm CPU tự chế)
- VGA/HDMI output qua Pmod cho GUI đơn giản
- Benchmark suite mở rộng: Dhrystone, Embench-IoT (ngoài CoreMark)

## 6. Process/Documentation

- Viết **architecture manual** riêng cho RVPRO32 khi làm xong mỗi phase (mirror tài liệu thật của công ty chip) — vừa củng cố kiến thức vừa làm portfolio
- Devlog/blog tiến độ — hữu ích khi cần hỏi cộng đồng RISC-V (r/RISCV, riscv-sw-dev mailing list) khi bị stuck

---

Nếu bạn muốn, tôi có thể cập nhật các mục này vào risc-v-plan.md — bạn có muốn tôi thêm phần "Mở rộng / Stretch Goals" vào file không?

````markdown
# Đánh giá tổng thể Plan RVPRO32

## Tổng quan

Đây không còn là một project CPU đơn thuần mà là một **ecosystem hoàn chỉnh**, bao gồm:

- CPU Architecture
- SoC Design
- Toolchain
- Operating System
- Verification
- FPGA Implementation

Nếu hoàn thành được toàn bộ, đây là một portfolio ở mức rất cao, tương đương một dự án nghiên cứu kéo dài nhiều năm.

---

# Điểm mạnh

## 1. Phân chia thành ba track

```
Hardware
        \
         \
          -------> Demo
         /
        /
Toolchain

Operating System
```

Ba track này phát triển song song nên không bị phụ thuộc hoàn toàn vào nhau.

Đây là cách tổ chức rất hợp lý.

---

## 2. Có chiến lược Bootstrap

Đây là điểm mình thích nhất.

Bạn không cố tự viết compiler ngay từ đầu.

Thay vào đó

```
GNU Toolchain
        ↓
Verify RTL
        ↓
Tự viết Assembler
        ↓
Tự viết Compiler
        ↓
Loại bỏ GNU
```

Đây là cách làm thực tế.

---

## 3. Roadmap rõ ràng

Project được chia thành nhiều phase nhỏ.

Ví dụ

```
Pipeline

↓

CSR

↓

MMU

↓

Cache

↓

SoC

↓

Compiler

↓

OS
```

Điều này giúp luôn biết mình đang ở đâu.

---

## 4. Scope hợp lý

Bạn đã loại bỏ

- RV64
- Vector Extension
- Double Precision

Điều này giúp project vẫn nằm trong khả năng của một người.

---

# Những điểm mình sẽ bổ sung

---

# 1. Thêm Architecture Specification

Hiện tại plan tập trung khá nhiều vào RTL.

Nhưng nên có thêm tài liệu mô tả kiến trúc.

Ví dụ

```
docs/

pipeline.md

hazard.md

csr.md

cache.md

mmu.md

interrupt.md

axi.md
```

Các tài liệu này mô tả:

- datapath
- timing
- forwarding
- exception flow
- memory model

Sau này viết RTL sẽ nhanh hơn rất nhiều.

---

# 2. Thêm Golden Reference Model

Nên có một mô hình chuẩn để so sánh.

```
            Spike

               ↑

RTL ---------------- Compare
```

Sau mỗi instruction retire

so sánh

- PC
- Register
- CSR
- Memory

Đây gọi là

> Lockstep Verification

Đây là phương pháp verify CPU được sử dụng rất nhiều trong công nghiệp.

---

# 3. Thêm Verification Plan

Hiện tại mới có test.

Nên có thêm bảng theo dõi.

Ví dụ

| Instruction | Normal | Hazard | Exception | Interrupt | Pass |
|------------|---------|----------|--------------|------------|------|
| ADD | ✅ | ✅ | - | - | ✅ |
| LW | ✅ | ✅ | ✅ | - | ✅ |
| CSRRW | ✅ | - | ✅ | - | ⏳ |

Sau này rất dễ biết mình còn thiếu gì.

---

# 4. Functional Coverage

Chạy nhiều testcase không đồng nghĩa đã test đủ.

Nên theo dõi coverage.

Ví dụ

```
Instruction Coverage

ADD

100%

SUB

100%

CSR

65%

Interrupt

20%
```

Điều này giúp biết còn thiếu testcase nào.

---

# 5. Assertion

Đừng chỉ dựa vào testbench.

Nên thêm assertion.

Ví dụ

```
assert(x0 == 0)
```

```
assert(!double_writeback)
```

```
assert(valid_pc)
```

Assertion giúp phát hiện bug rất sớm.

---

# 6. Performance Counter

Ngoài

```
mcycle
```

nên bổ sung

```
cache miss

cache hit

TLB miss

pipeline stall

branch mispredict

flush

interrupt count
```

Sau này chạy benchmark sẽ biết CPU đang chậm ở đâu.

---

# 7. Trace Logger

Nên có module ghi trace.

Ví dụ

```
PC

Instruction

Destination Register

Write Data
```

Xuất thành

```
00001000

addi x1,x0,5

x1 = 5
```

Debug sẽ dễ hơn rất nhiều.

---

# 8. AXI Monitor

Nếu dùng AXI4

nên có

```
axi_checker.v
```

Kiểm tra

- VALID
- READY
- Burst
- ID
- Length
- Response

Đây là kỹ thuật rất phổ biến trong verification.

---

# 9. Cache Simulator

Trước khi viết RTL

nên viết simulator bằng Python.

```
Memory Trace

↓

Python Cache

↓

Hit

Miss

Replacement

Statistics
```

Sau khi thuật toán đúng mới viết RTL.

---

# 10. Branch Predictor Simulator

Tương tự.

Viết Python trước.

```
Trace

↓

Predictor

↓

Accuracy
```

Sau đó mới RTL.

---

# 11. Compiler

Hiện tại

```
Parser

↓

Assembly
```

Theo mình nên thêm

```
Lexer

↓

Parser

↓

AST

↓

Intermediate Representation

↓

Optimization

↓

Register Allocation

↓

Assembly
```

IR sẽ giúp compiler mở rộng dễ hơn rất nhiều.

---

# 12. Mini Standard Library

Sau compiler nên viết

```
RVPRO-LIBC
```

Bao gồm

```
printf

malloc

free

memcpy

strlen

strcmp

memset
```

Điều này giúp OS dễ phát triển hơn.

---

# 13. Debug Infrastructure

Nên có

```
UART Console

↓

Register Dump

↓

Memory Dump

↓

Exception Dump

↓

Stack Dump
```

Khi kernel panic

có thể in toàn bộ trạng thái hệ thống.

---

# 14. Documentation

Mình khuyến nghị tạo bộ tài liệu riêng.

```
docs/

ISA Manual

Programmer Guide

Hardware Manual

Boot Flow

Memory Map

ABI

Compiler Guide

OS Guide
```

Đây sẽ là phần rất giá trị trong portfolio.

---

# 15. Thay đổi thứ tự phát triển

Hiện tại roadmap gần giống

```
CPU

↓

Compiler

↓

OS
```

Mình đề xuất chuyển sang mô hình **Vertical Slice**.

```
CPU tối thiểu

↓

UART

↓

Hello World

↓

Interrupt

↓

Timer

↓

Shell đơn giản

↓

MMU

↓

Process

↓

Cache

↓

Compiler

↓

OS hoàn chỉnh
```

Lợi ích:

- Luôn có hệ thống chạy được.
- Phát hiện lỗi tích hợp sớm.
- Có milestone rõ ràng.
- Không bị "chết chìm" trong một module quá lớn.

---

# Kiến trúc hoàn chỉnh mình đề xuất

```
                 RVPRO32

                    │

        ┌───────────┼────────────┐

        │           │            │

   Hardware     Verification   Documentation

        │           │            │

        ├──────┐    │    ┌───────┤

        │      │    │    │

   RTL   FPGA  Formal  Lockstep

        │      │

        └──────┴──────────────┐

                              │

                         Toolchain

                              │

            Assembler → Linker → Compiler → LibC

                              │

                              ▼

                         Operating System

                              │

                    Scheduler

                    Memory

                    File System

                    Drivers

                    Shell
```

---

# Đánh giá cuối cùng

| Tiêu chí | Đánh giá |
|----------|-----------|
| Kiến trúc | ⭐⭐⭐⭐⭐ |
| Giá trị học tập | ⭐⭐⭐⭐⭐ |
| Verification | ⭐⭐⭐⭐☆ *(nên bổ sung Lockstep, Coverage, Assertion)* |
| Compiler | ⭐⭐⭐⭐☆ *(nên bổ sung IR và LibC)* |
| OS | ⭐⭐⭐⭐⭐ |
| Portfolio | ⭐⭐⭐⭐⭐ |
| Tính khả thi | ⭐⭐⭐⭐☆ *(2–3 năm bán thời gian)* |

## Kết luận

Đây là một roadmap rất mạnh và có chiều sâu. Tuy nhiên, để đạt chất lượng tương đương các dự án CPU chuyên nghiệp (như Rocket Chip, BOOM, CVA6 hay lowRISC Ibex), mình khuyến nghị bổ sung thêm bốn trụ cột còn thiếu:

1. **Architecture Documentation** (đặc tả vi kiến trúc trước khi viết RTL).
2. **Verification Infrastructure** (Lockstep, Assertion, Functional Coverage, Golden Model).
3. **Performance Analysis** (Performance Counters, Trace Logger, Cache/Branch Simulator).
4. **Compiler Infrastructure** (Intermediate Representation, LibC, Debug Tools).

Nếu bổ sung các phần này, RVPRO32 sẽ không chỉ là một CPU RISC-V tự viết mà sẽ trở thành **một nền tảng nghiên cứu và phát triển hoàn chỉnh**, bao phủ toàn bộ chuỗi từ **ISA → RTL → SoC → Toolchain → Operating System → FPGA Validation**.
````


