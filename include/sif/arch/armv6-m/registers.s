// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * registers.s -- armv6-m registers
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	// B1.5.2
	.set EXCEPTION_NUMBER_SYSTICK, 15

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

	// B3.3.2
	.set SYST_CSR,   0xe000e010
	.set SYST_RVR,   0xe000e014
	.set SYST_CVR,   0xe000e018
	.set SYST_CALIB, 0xe000e01c

	// B3.3.3
	.set SYST_CSR_COUNTFLAG, 1 << 16
	.set SYST_CSR_CLKSOURCE, 1 << 2
	.set SYST_CSR_TICKINIT,  1 << 1
	.set SYST_CSR_ENABLE,    1 << 0
