// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * registers.s -- armv6-m registers
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	// B1.4.2
	.set EPSR_T, 24

	// B1.4.4
	.set NPRIV, 0
	.set SPEL,  1

	// B1.5.2
	.set EXCEPTION_NUMBER_PENDSV,  14
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

	// B3.2.10
	.set SHPR3_PRI_15, 30
	.set SHPR3_PRI_14, 22

	// B3.3.2
	.set SYST_CSR,   0xe000e010
	.set SYST_RVR,   0xe000e014
	.set SYST_CVR,   0xe000e018
	.set SYST_CALIB, 0xe000e01c

	// B3.3.3
	.set SYST_CSR_COUNTFLAG, 16
	.set SYST_CSR_CLKSOURCE, 2
	.set SYST_CSR_TICKINIT,  1
	.set SYST_CSR_ENABLE,    0

	// B3.2.4
	.set ICSR_NMIPENDSET,  31
	.set ICSR_PENDSVSET,   28
	.set ICSR_PENDSVCLR,   27
	.set ICSR_PENDSTSET,   26
	.set ICSR_PENDSTCLR,   25
	.set ICSR_ISRPREEMPT,  23
	.set ICSR_ISRPENDING,  22
	.set ICSR_VECTPENDING, 12
	.set ICSR_VECTACTIVE,  0
