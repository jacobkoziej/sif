// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.s -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6-m

	.include "sif/arch/armv6-m/macros.s"
	.include "sif/arch/armv6-m/registers.s"

	.text

	.type   sif_arch_armv6_m_init, %function
	.global sif_arch_armv6_m_init
sif_arch_armv6_m_init:
	push {lr}
	bl   sif_arch_armv6_m_setup_nvic
	pop  {pc}

	.type   sif_arch_armv6_m_init_stack, %function
	.global sif_arch_armv6_m_init_stack
sif_arch_armv6_m_init_stack:
	sub r0, r0, #EXCEPTION_OFFSET

	str r1, [r0, #PC_OFFSET]
	str r2, [r0, #R0_OFFSET]

	ldr r1, =sif_task_delete
	str r1, [r0, #LR_OFFSET]

	ldr r1, =(1 << EPSR_T)
	str r1, [r0, #XPSR_OFFSET]

	sub r0, r0, #CONTEXT_OFFSET

	bx lr

	.type   sif_arch_armv6_m_handler_systick, %function
sif_arch_armv6_m_handler_systick:
	push {lr}
	bl sif_tick_step
	pop {pc}

	.type   sif_arch_armv6_m_scheduler_start, %function
	.global sif_arch_armv6_m_scheduler_start
sif_arch_armv6_m_scheduler_start:
	// reset msp
	ldr r1,  =VTOR
	ldr r1,  [r1]
	ldr r1,  [r1]
	msr msp, r1

	// pop context
	mov r1, r0
	add r1, r1,  #CONTEXT_OFFSET
	ldr r3, [r1, #PC_OFFSET]
	ldr r2, [r1, #XPSR_OFFSET]
	ldr r0, [r1, #R0_OFFSET]
	add r1, r1,  #EXCEPTION_OFFSET

	// set special registers
	msr psp,        r1
	msr apsr_nzcvq, r2

	// switch to psp and jump to task
	ldr   r1,      =(1 << SPEL)
	msr   control, r1
	isb
	cpsie i
	bx    r3

	.type   sif_arch_armv6_m_setup_nvic, %function
sif_arch_armv6_m_setup_nvic:
	push {lr}

	bl sif_arch_armv6_m_setup_systick

	// load vector table
	ldr r2, =VTOR
	ldr r2, [r2]

	SETUP_EXCEPTION_HANDLER r2, EXCEPTION_NUMBER_SYSTICK, sif_arch_armv6_m_handler_systick

	// ensure SCS registers are updated (B2.5)
	dsb
	isb

	pop {pc}

	.type   sif_arch_armv6_m_setup_systick, %function
sif_arch_armv6_m_setup_systick:
	// program our reload value
	ldr r0, =SYST_RVR
	ldr r1, =SIF_ARCH_ARMV6_M_SYST_RVR_RELOAD
	ldr r1, [r1]
	str r1, [r0]

	// any write clears the current value
	ldr r0, =SYST_CVR
	str r1, [r0]

	// program control and status register
	ldr r0, =SYST_CSR
	ldr r1, =((1 << SYST_CSR_CLKSOURCE) | (1 << SYST_CSR_TICKINIT) | (1 << SYST_CSR_ENABLE))
	str r1, [r0]

	// set systick priority
	ldr r1, =SIF_ARCH_ARMV6_M_KERNEL_PRIORITY
	ldr r1, [r1]
	lsl r1, r1, #SHPR3_PRI_15
	ldr r0, =SHPR3
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr
