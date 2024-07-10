// SPDX-License-Identifier: MPL-2.0
/*
 * port.h -- armv6s-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ARCH_ARMV6S_M_PORT_H
#define SIF_ARCH_ARMV6S_M_PORT_H

#include <sif/arch/armv6s-m/port-asm.h>

extern const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_KERNEL_PRIORITY;
extern const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_SYSTEM_CLOCK_HZ;
extern const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_SYSTICK_HZ;
extern const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_SYST_RVR_RELOAD;

void sif_arch_armv6s_m_init(void);

#endif	// SIF_ARCH_ARMV6S_M_PORT_H
