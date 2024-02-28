// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * config.h -- rp2040 default config
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_MARCH_RP2040_PORT_CONFIG_H
#define SIF_MARCH_RP2040_PORT_CONFIG_H

#define SIF_CONFIG_MAXIMUM_TASKS 8

#define SIF_CONFIG_MINIMUM_STACK_SIZE 128

#define SIF_CONFIG_SYSTEM_CLOCK_HZ 125000000ul

#define SIF_CONFIG_SYSTICK_HZ 100

#endif	// SIF_MARCH_RP2040_PORT_CONFIG_H
