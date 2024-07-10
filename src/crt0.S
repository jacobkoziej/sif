// SPDX-License-Identifier: MPL-2.0
/*
 * crt0.S -- c runtime
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6s-m
	.cpu  cortex-m0plus

#include <sif/arch/armv6s-m/registers.h>

	.text

	.section .text._start, "ax", %progbits

	.type   _start, %function
	.global _start
_start:
	// initialize vector table
	ldr r0, =_vectors
	ldr r1, =VTOR
	str r0, [r1]
	dsb
	isb

	// reset msp
	ldr r0,  [r0]
	msr msp, r0

#ifndef NO_FLASH
	// load .data
	ldr r1, =__data_load__
	ldr r2, =__data_start__
	ldr r3, =__data_end__
	b   1f

0:
	ldm r1!, {r0}
	stm r2!, {r0}
1:
	cmp r2, r3
	blt 0b
#endif  // NO_FLASH

	// zero .bss
	mov r0, #0
	ldr r1, =__bss_start__
	ldr r2, =__bss_end__
	b   1f

0:
	stm r1!, {r0}
1:
	cmp r1, r2
	blt 0b

	// jump to main
	ldr r0, =main
	bx  r0

1:
	bkpt
	b 1b
