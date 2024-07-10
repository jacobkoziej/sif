// SPDX-License-Identifier: MPL-2.0
/*
 * port.c -- armv6s-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/arch/armv6s-m/port-asm.h>
#include <sif/arch/armv6s-m/port.h>
#include <sif/arch/armv6s-m/types.h>
#include <sif/config.h>

const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_KERNEL_PRIORITY
	= SIF_CONFIG_KERNEL_PRIORITY;
const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_SYSTEM_CLOCK_HZ
	= SIF_CONFIG_SYSTEM_CLOCK_HZ;
const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_SYSTICK_HZ
	= SIF_CONFIG_SYSTICK_HZ;

const sif_arch_armv6s_m_word_t SIF_ARCH_ARMV6S_M_SYST_RVR_RELOAD
	= (SIF_ARCH_ARMV6S_M_SYSTEM_CLOCK_HZ / SIF_ARCH_ARMV6S_M_SYSTICK_HZ)
	- 1;
