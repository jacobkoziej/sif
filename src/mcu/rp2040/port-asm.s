// SPDX-License-Identifier: MPL-2.0
/*
 * port-asm.s -- rp2040 port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6s-m
	.cpu  cortex-m0plus

	.include "sif/mcu/rp2040/registers.s"

	.text

	.type   sif_mcu_rp2040_get_coreid, %function
	.global sif_mcu_rp2040_get_coreid
sif_mcu_rp2040_get_coreid:
	ldr r0, =COREID
	ldr r0, [r0]
	bx  lr

	.type   sif_mcu_rp2040_init, %function
	.global sif_mcu_rp2040_init
sif_mcu_rp2040_init:
	push  {lr}
	cpsid i
	bl    sif_arch_armv6_m_init
	cpsie i
	pop   {pc}

	.type   sif_mcu_rp2040_kernel_lock, %function
	.global sif_mcu_rp2040_kernel_lock
sif_mcu_rp2040_kernel_lock:
	ldr r1, =SPINLOCK15

.Lacquire_kernel_spinlock:
	ldr r0, [r1]
	tst r0, r0
	beq .Lacquire_kernel_spinlock

	dmb

	bx lr

	.type   sif_mcu_rp2040_kernel_unlock, %function
	.global sif_mcu_rp2040_kernel_unlock
sif_mcu_rp2040_kernel_unlock:
	ldr r0, =SPINLOCK15

	dmb

	// release spinlock
	str r0, [r0]

	bx lr

	.type   sif_mcu_rp2040_scheduler_start, %function
	.global sif_mcu_rp2040_scheduler_start
sif_mcu_rp2040_scheduler_start:
	b sif_arch_armv6_m_scheduler_start

	.type   sif_mcu_rp2040_test_and_set, %function
	.global sif_mcu_rp2040_test_and_set
sif_mcu_rp2040_test_and_set:
	ldr r2, =SPINLOCK14

	// preserve primask
	mrs r3, primask

	// disable interrupts and synchronize
	// so that we have a consistent view
	cpsid i
	dmb

.Lacquire_test_and_set_spinlock:
	ldr r1, [r2]
	tst r1, r1
	beq .Lacquire_test_and_set_spinlock

	ldr r1, [r0]
	tst r1, r1
	bne .Ltest_failed

	// set
	mov r1, #1
	str r1, [r0]
	mov r1, #0

.Ltest_failed:
	// release spinlock
	str r2, [r2]

	// synchronize and restore primask
	// so that we have a consistent view
	dsb
	msr primask, r3

	mov r0, r1
	bx  lr
