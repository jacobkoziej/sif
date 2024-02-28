// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.s -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6-m

	.include "sif/arch/armv6-m/macros.s"
	.include "sif/arch/armv6-m/registers.s"

	.text

	.type   sif_arch_armv6_m_handler_systick, %function
sif_arch_armv6_m_handler_systick:
	push {lr}
	bl sif_tick_step
	pop {pc}

	.type   sif_arch_armv6_m_setup_nvic, %function
	.global sif_arch_armv6_m_setup_nvic
sif_arch_armv6_m_setup_nvic:
	push {lr}

	bl sif_arch_armv6_m_setup_systick

	// load vector table
	ldr r2, =VTOR
	ldr r2, [r2]

	SETUP_EXCEPTION_HANDLER r2, EXCEPTION_NUMBER_SYSTICK, sif_arch_armv6_m_handler_systick

	dmb

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

	// set systick to lowest priority
	ldr r0, =SHPR3
	ldr r1, =(0x03 << SHPR3_PRI_15)
	ldr r2, =SHPR3_PRI_15
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr
