// SPDX-License-Identifier: MPL-2.0
/*
 * shared.S -- shared stage2 bootloader
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.syntax unified

	.arch armv6s-m
	.cpu  cortex-m0plus

#include "ssi.h"

#include <sif/arch/armv6s-m/registers.h>

#define FLASH_VECTOR_TABLE 0x10000100

	.text

	.section .text._start, "ax", %progbits

	.type   _start, %function
	.global _start
_start:
	mov r0, lr

	cmp r0, #0
	bne .Labort_stage2

	bl stage2

	ldr r0, =FLASH_VECTOR_TABLE
	ldr r1, =VTOR
	str r0, [r1]
	ldr r0, [r0, #4]

.Labort_stage2:
	bx r0

	.section .text.flush_ssi_tx_fifo, "ax", %progbits

	.type   flush_ssi_tx_fifo, %function
	.global flush_ssi_tx_fifo
flush_ssi_tx_fifo:
	movs r1, #(1 << SSI_SR_TFE_SHIFT)
	movs r2, #(1 << SSI_SR_BUSY_SHIFT)

.Lpoll_tx_fifo:
	ldr r3, [r0, #SSI_SR_OFFSET]
	tst r3, r1
	beq .Lpoll_tx_fifo
	tst r3, r2
	bne .Lpoll_tx_fifo

	mov pc, lr

	.section .text.read_status_register, "ax", %progbits

	.type   read_status_register, %function
	.global read_status_register
read_status_register:
	push {r4, lr}

	mov r4, r0

	str r1, [r4, #SSI_DR0_OFFSET]
	str r1, [r4, #SSI_DR0_OFFSET]

	bl flush_ssi_tx_fifo

	ldr r0, [r4, #SSI_DR0_OFFSET]
	ldr r0, [r4, #SSI_DR0_OFFSET]

	pop {r4, pc}
