// SPDX-License-Identifier: MPL-2.0
/*
 * crt0.S -- c runtime
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.syntax unified

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
	ldr r4, =__copy_start__
	ldr r5, =__copy_end__
	b   .Lget_next_copy_section

.Lprepare_next_copy_section:
	ldm r4!, {r0-r2}
	cmp r2,  #0
	beq .Lget_next_copy_section

	add r2, r0

.Lcopy_section:
	ldm r1!, {r3}
	stm r0!, {r3}

	cmp r0, r2
	blt .Lcopy_section

.Lget_next_copy_section:
	cmp r4, r5
	blt .Lprepare_next_copy_section
#endif  // NO_FLASH

	movs r2, #0

	ldr r4, =__zero_start__
	ldr r5, =__zero_end__
	b   .Lget_next_zero_section

.Lprepare_next_zero_section:
	ldm r4!, {r0-r1}
	cmp r1,  #0
	beq .Lget_next_zero_section

	add r1, r0

.Lzero_section:
	stm r0!, {r2}

	cmp r0, r1
	blt .Lzero_section

.Lget_next_zero_section:
	cmp r4, r5
	blt .Lprepare_next_zero_section

	ldr r0, =main
	bx  r0

.Lexit:
	bkpt
	b .Lexit
