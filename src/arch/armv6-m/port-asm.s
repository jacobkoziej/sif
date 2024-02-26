// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.s -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6-m

	.text

	.type   sif_arch_armv6_m_nvic_setup, %function
	.global sif_arch_armv6_m_nvic_setup
sif_arch_armv6_m_nvic_setup:
	bx lr
