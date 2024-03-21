// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port.c -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/arch/armv6-m/port-asm.h>
#include <sif/arch/armv6-m/port.h>
#include <sif/arch/armv6-m/types.h>
#include <sif/config.h>

const sif_arch_armv6_m_word_t SIF_ARCH_ARMV6_M_SYSTEM_CLOCK_HZ
    = SIF_CONFIG_SYSTEM_CLOCK_HZ;
const sif_arch_armv6_m_word_t SIF_ARCH_ARMV6_M_SYSTICK_HZ
    = SIF_CONFIG_SYSTICK_HZ;

const sif_arch_armv6_m_word_t SIF_ARCH_ARMV6_M_SYST_RVR_RELOAD
    = (SIF_ARCH_ARMV6_M_SYSTEM_CLOCK_HZ / SIF_ARCH_ARMV6_M_SYSTICK_HZ) - 1;
