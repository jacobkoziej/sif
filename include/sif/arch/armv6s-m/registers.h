// SPDX-License-Identifier: MPL-2.0
/*
 * registers.h -- armv6s-m registers
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ARCH_ARMV6S_M_REGISTERS_H
#define SIF_ARCH_ARMV6S_M_REGISTERS_H

#ifndef __ASSEMBLER__
#include <sif/arch/armv6s-m/types.h>
#else  // __ASSEMBLER__
#define sif_arch_armv6s_m_register_t
#endif	// __ASSEMBLER__

// B1.4.2
#define EPSR_T 24

// B1.4.4
#define NPRIV 0
#define SPEL  1

// B1.5.2
#define EXCEPTION_NUMBER_SVCALL	 11
#define EXCEPTION_NUMBER_PENDSV	 14
#define EXCEPTION_NUMBER_SYSTICK 15

// B1.5.8
#define EXEC_RETURN_HANDLER_MODE    0xfffffff1
#define EXEC_RETURN_THREAD_MODE_MSP 0xfffffff9
#define EXEC_RETURN_THREAD_MODE_PSP 0xfffffffd

// B3.2.2
#define ACTLR (sif_arch_armv6s_m_register_t 0xe000e008)
#define CPUID (sif_arch_armv6s_m_register_t 0xe000ed00)
#define ICSR  (sif_arch_armv6s_m_register_t 0xe000ed04)
#define VTOR  (sif_arch_armv6s_m_register_t 0xe000ed08)
#define AIRCR (sif_arch_armv6s_m_register_t 0xe000ed0c)
#define SCR   (sif_arch_armv6s_m_register_t 0xe000ed10)
#define CCR   (sif_arch_armv6s_m_register_t 0xe000ed14)
#define SHPR2 (sif_arch_armv6s_m_register_t 0xe000ed1c)
#define SHPR3 (sif_arch_armv6s_m_register_t 0xe000ed20)
#define DFSR  (sif_arch_armv6s_m_register_t 0xe000ed30)

// B3.2.9
#define SHPR2_PRI_11 30

// B3.2.10
#define SHPR3_PRI_15 30
#define SHPR3_PRI_14 22

// B3.3.2
#define SYST_CSR   (sif_arch_armv6s_m_register_t 0xe000e010)
#define SYST_RVR   (sif_arch_armv6s_m_register_t 0xe000e014)
#define SYST_CVR   (sif_arch_armv6s_m_register_t 0xe000e018)
#define SYST_CALIB (sif_arch_armv6s_m_register_t 0xe000e01c)

// B3.3.3
#define SYST_CSR_COUNTFLAG 16
#define SYST_CSR_CLKSOURCE 2
#define SYST_CSR_TICKINIT  1
#define SYST_CSR_ENABLE	   0

// B3.3.5
#define SYST_CVR_CURRENT 0

// B3.2.4
#define ICSR_NMIPENDSET	 31
#define ICSR_PENDSVSET	 28
#define ICSR_PENDSVCLR	 27
#define ICSR_PENDSTSET	 26
#define ICSR_PENDSTCLR	 25
#define ICSR_ISRPREEMPT	 23
#define ICSR_ISRPENDING	 22
#define ICSR_VECTPENDING 12
#define ICSR_VECTACTIVE	 0

#endif	// SIF_ARCH_ARMV6S_M_REGISTERS_H
