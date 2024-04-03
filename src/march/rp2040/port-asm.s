// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.s -- rp2040 port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6s-m
	.cpu  cortex-m0plus

	.include "sif/march/rp2040/registers.s"

	.text

	.type   sif_march_rp2040_get_coreid, %function
	.global sif_march_rp2040_get_coreid
sif_march_rp2040_get_coreid:
	ldr r0, =COREID
	ldr r0, [r0]
	bx  lr

	.type   sif_march_rp2040_init, %function
	.global sif_march_rp2040_init
sif_march_rp2040_init:
	push  {lr}
	cpsid i
	bl    sif_arch_armv6_m_init
	cpsie i
	pop   {pc}

	.type   sif_march_rp2040_kernel_lock, %function
	.global sif_march_rp2040_kernel_lock
sif_march_rp2040_kernel_lock:
	ldr r1, =SPINLOCK15

.Lacquire_kernel_spinlock:
	ldr r0, [r1]
	tst r0, r0
	beq .Lacquire_kernel_spinlock

	dmb

	bx lr

	.type   sif_march_rp2040_kernel_unlock, %function
	.global sif_march_rp2040_kernel_unlock
sif_march_rp2040_kernel_unlock:
	ldr r0, =SPINLOCK15

	dmb

	// release spinlock
	str r0, [r0]

	bx lr

	.type   sif_march_rp2040_scheduler_start, %function
	.global sif_march_rp2040_scheduler_start
sif_march_rp2040_scheduler_start:
	push {lr}

	bl sif_arch_armv6_m_scheduler_start

	// panic! something's gone horribly wrong
	pop {pc}

	.type   sif_march_rp2040_test_and_set, %function
	.global sif_march_rp2040_test_and_set
sif_march_rp2040_test_and_set:
	ldr r3, =SPINLOCK14

	// disable interrupts and synchronize
	// so that we have a consistent view
	cpsid i
	dmb

.Lacquire_test_and_set_spinlock:
	ldr r2, [r3]
	tst r2, r2
	beq .Lacquire_test_and_set_spinlock

	ldr r1, [r0]
	tst r1, r1
	bne .Ltest_failed

	// set
	mov r2, #1
	str r2, [r0]

.Ltest_failed:
	// release spinlock
	str r3, [r3]

	// synchronize and enable interrupts
	// so that we have a consistent view
	dsb
	cpsie i

	mov r0, r1
	bx  lr
