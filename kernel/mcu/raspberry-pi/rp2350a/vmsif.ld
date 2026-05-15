/* SPDX-License-Identifier: MPL-2.0 */
/*
 * vmsif.ld -- rp2350a virtual memory kernel
 * Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
 */

INCLUDE "mcu/raspberry-pi/rp2350a/memory.ld"

REGION_ALIAS("ro_lm", KERNEL_SRAM)
REGION_ALIAS("ro_vm", KERNEL_SRAM)
REGION_ALIAS("rw_vm", KERNEL_SRAM)

INCLUDE "entry.ld"
INCLUDE "sections.ld"
INCLUDE "arch/arm/sections.ld"
