// SPDX-License-Identifier: MPL-2.0
//
// start.rs -- early Arm initialization
// Copyright (C) 2026--2024  Jacob Koziej <jacobkoziej@gmail.com>

use crate::scs::scb;
use core::arch::naked_asm;
use core::mem::{offset_of, size_of};
use sif_core::elf::{Header, Phdr};

#[unsafe(naked)]
#[unsafe(export_name = "_start_arch")]
#[unsafe(link_section = ".text._start")]
pub(crate) extern "C" fn start() {
    #[rustfmt::skip]
    naked_asm!(
r#"
    cpsid i

    ehdr    .req r0
    e_phnum .req r1
    e_phoff .req r2

    ldr ehdr, =__rodata_ehdr__

    ldrh e_phnum, [ehdr, #{E_PHNUM}]
    ldr  e_phoff, [ehdr, #{E_PHOFF}]

    phdr .req r2

    add phdr, ehdr, e_phoff

    .unreq e_phoff

    tmp  .req r6
    zero .req r7

    movs r7, #0

.Lsegment_load_loop:
    cbz e_phnum, .Ldone

    p_paddr .req r3
    p_vaddr .req r4

    ldr p_paddr, [phdr, #{P_PADDR}]
    ldr p_vaddr, [phdr, #{P_VADDR}]

    cmp p_paddr, p_vaddr
    beq .Lnext_segment

    p_filesz .req r5
    copy_end .req r5

    ldr p_filesz, [phdr, #{P_FILESZ}]
    add copy_end, p_vaddr, p_filesz

    .unreq p_filesz

.Lcopy:
    cmp p_vaddr, copy_end
    bge .Lcopy_done

    ldr tmp, [p_paddr], #4
    str tmp, [p_vaddr], #4

    b .Lcopy

    .unreq copy_end

.Lcopy_done:
    p_memsz  .req r5
    zero_end .req r5

    ldr p_memsz, [phdr, #{P_MEMSZ}]
    add zero_end, p_vaddr, p_memsz

    .unreq p_memsz

.Lzero:
    cmp p_vaddr, zero_end
    bge .Lzero_done

    str zero, [p_vaddr], #4

    b .Lzero

    .unreq zero_end

    .unreq p_vaddr
    .unreq p_paddr

    .unreq tmp
    .unreq zero

.Lzero_done:
.Lnext_segment:
    add phdr, #{PHDR_SIZE}
    sub e_phnum, #1

    b .Lsegment_load_loop

    .unreq phdr
    .unreq e_phnum
    .unreq ehdr

.Ldone:
    ldr r0, =vector_table
    ldr r1, ={VTOR}
    str r0, [r1]
    dsb sy
    isb

    ldr r0,  =__swapper_stack_end__
    msr msp, r0

    // TODO: reset if we return from main
    ldr lr, =0xFFFFFFFF

    ldr r0, =main
    bx  r0
"#,
E_PHOFF = const offset_of!(Header, e_phoff),
E_PHNUM = const offset_of!(Header, e_phnum),
P_PADDR = const offset_of!(Phdr, p_paddr),
P_VADDR = const offset_of!(Phdr, p_vaddr),
P_FILESZ = const offset_of!(Phdr, p_filesz),
P_MEMSZ = const offset_of!(Phdr, p_memsz),
PHDR_SIZE = const size_of::<Phdr>(),
VTOR = const scb::BASE + scb::offset::VTOR,
);
}
