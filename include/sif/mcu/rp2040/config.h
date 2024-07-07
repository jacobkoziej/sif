// SPDX-License-Identifier: MPL-2.0
/*
 * config.h -- rp2040 default config
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_MCU_RP2040_PORT_CONFIG_H
#define SIF_MCU_RP2040_PORT_CONFIG_H

#define SIF_CONFIG_CORES 2

#define SIF_CONFIG_KERNEL_PRIORITY 0x01

#define SIF_CONFIG_MAXIMUM_TASKS 8

#define SIF_CONFIG_MINIMUM_STACK_SIZE 128

#define SIF_CONFIG_PRIORITY_LEVELS 4

#define SIF_CONFIG_STACK_ALIGNMENT_MASK 0x07

#define SIF_CONFIG_STACK_GROWTH_DIRECTION -1

#define SIF_CONFIG_SYSTEM_CLOCK_HZ 125000000ul

#define SIF_CONFIG_SYSTICK_HZ 100

#endif	// SIF_MCU_RP2040_PORT_CONFIG_H
