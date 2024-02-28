// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.s -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6-m

	.include "sif/arch/armv6-m/registers.s"

	.text

	.type   sif_arch_armv6_m_nvic_setup, %function
	.global sif_arch_armv6_m_nvic_setup
sif_arch_armv6_m_nvic_setup:
	bl sif_arch_armv6_m_setup_systick
	bx lr

	.type   sif_arch_armv6_m_setup_systick, %function
sif_arch_armv6_m_setup_systick:
	// program our reload value
	ldr r0, =SYST_RVR
	ldr r1, =sif_arch_armv6_m_syst_rvr_reload
	ldr r1, [r1]
	str r1, [r0]

	// any write clears the current value
	ldr r0, =SYST_CVR
	str r1, [r0]

	// program control and status register
	ldr r0, =SYST_CSR
	ldr r1, =(SYST_CSR_CLKSOURCE | SYST_CSR_TICKINIT | SYST_CSR_ENABLE)
	str r1, [r0]

	bx lr
