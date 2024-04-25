// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port.h -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ARCH_ARMV6_M_PORT_H
#define SIF_ARCH_ARMV6_M_PORT_H

#include <sif/arch/armv6-m/port-asm.h>

extern const sif_arch_armv6_m_word_t SIF_ARCH_ARMV6_M_KERNEL_PRIORITY;
extern const sif_arch_armv6_m_word_t SIF_ARCH_ARMV6_M_SYSTEM_CLOCK_HZ;
extern const sif_arch_armv6_m_word_t SIF_ARCH_ARMV6_M_SYSTICK_HZ;
extern const sif_arch_armv6_m_word_t SIF_ARCH_ARMV6_M_SYST_RVR_RELOAD;

void sif_arch_armv6_m_init(void);

#endif	// SIF_ARCH_ARMV6_M_PORT_H
