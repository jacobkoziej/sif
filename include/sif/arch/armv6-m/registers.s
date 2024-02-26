// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * registers.s -- armv6-m registers
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	// B3.2.2
	.set ACTLR, 0xe000e008
	.set CPUID, 0xe000ed00
	.set ICSR,  0xe000ed04
	.SET VTOR,  0xe000ed08
	.set AIRCR, 0xe000ed0c
	.set SCR,   0xe000ed10
	.set CCR,   0xe000ed14
	.set SHPR2, 0xe000ed1c
	.set SHPR3, 0xe000ed20
	.set DFSR,  0xe000ed30
