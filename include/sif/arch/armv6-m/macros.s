// SPDX-License-Identifier: MPL-2.0
/*
 * macros.s -- armv6-m macros
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.set CONTEXT_OFFSET,   32
	.set EXCEPTION_OFFSET, 32
	.set LR_OFFSET,        0x14
	.set PC_OFFSET,        0x18
	.set R0_OFFSET,        0x00
	.set R1_OFFSET,        0x04
	.set XPSR_OFFSET,      0x1c

	.macro RESTORE_CONTEXT sp
	ldmia \sp!, {r4-r7}
	mov   r8,   r4
	mov   r9,   r5
	mov   r10,  r6
	mov   r11,  r7
	ldmia \sp!, {r4-r7}
	msr   psp,  \sp
	.endm

	.macro SAVE_CONTEXT sp
	mrs \sp, psp

	// save registers r4-r7
	sub   \sp,  \sp, #(CONTEXT_OFFSET - 16)
	stmia \sp!, {r4-r7}

	// save registers r8-r11
	mov   r4,   r8
	mov   r5,   r9
	mov   r6,   r10
	mov   r7,   r11
	sub   \sp,  \sp, #CONTEXT_OFFSET
	stmia \sp!, {r4-r7}

	// ensure \sp is at CONTEXT_OFFSET
	sub \sp, \sp, #(CONTEXT_OFFSET - 16)
	.endm

	.macro SETUP_EXCEPTION_HANDLER vector_table, exception, handler
	mov r1, #(\exception * 4)
	add r1, r1, \vector_table
	ldr r0, =\handler
	str r0, [r1]
	.endm
