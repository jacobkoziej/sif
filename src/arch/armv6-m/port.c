// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port.c -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/arch/armv6-m/types.h>
#include <sif/config.h>

const sif_arch_armv6_m_word_t sif_arch_armv6_m_system_clock_hz
    = SIF_CONFIG_SYSTEM_CLOCK_HZ;
const sif_arch_armv6_m_word_t sif_arch_armv6_m_systick_hz
    = SIF_CONFIG_SYSTICK_HZ;
