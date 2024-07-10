// SPDX-License-Identifier: MPL-2.0
/*
 * registers.h -- rp2040 registers
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_MCU_RP2040_REGISTERS_H
#define SIF_MCU_RP2040_REGISTERS_H

#ifndef __ASSEMBLER__
#include <sif/mcu/rp2040/types.h>
#else  // __ASSEMBLER__
#define sif_mcu_rp2040_register_t
#endif	// __ASSEMBLER__

#define _SIO(X) (0xd0000000 + (X))

// 2.3.1
#define SIO_BASE (sif_mcu_rp2040_register_t _SIO(0x000))

// 2.3.1.1
#define CPUID (sif_mcu_rp2040_register_t _SIO(0x000))

// 2.3.1.3
#define SPINLOCK0   (sif_mcu_rp2040_register_t _SIO(0x100))
#define SPINLOCK1   (sif_mcu_rp2040_register_t _SIO(0x104))
#define SPINLOCK2   (sif_mcu_rp2040_register_t _SIO(0x108))
#define SPINLOCK3   (sif_mcu_rp2040_register_t _SIO(0x10c))
#define SPINLOCK4   (sif_mcu_rp2040_register_t _SIO(0x110))
#define SPINLOCK5   (sif_mcu_rp2040_register_t _SIO(0x114))
#define SPINLOCK6   (sif_mcu_rp2040_register_t _SIO(0x118))
#define SPINLOCK7   (sif_mcu_rp2040_register_t _SIO(0x11c))
#define SPINLOCK8   (sif_mcu_rp2040_register_t _SIO(0x120))
#define SPINLOCK9   (sif_mcu_rp2040_register_t _SIO(0x124))
#define SPINLOCK10  (sif_mcu_rp2040_register_t _SIO(0x128))
#define SPINLOCK11  (sif_mcu_rp2040_register_t _SIO(0x12c))
#define SPINLOCK12  (sif_mcu_rp2040_register_t _SIO(0x130))
#define SPINLOCK13  (sif_mcu_rp2040_register_t _SIO(0x134))
#define SPINLOCK14  (sif_mcu_rp2040_register_t _SIO(0x138))
#define SPINLOCK15  (sif_mcu_rp2040_register_t _SIO(0x13c))
#define SPINLOCK16  (sif_mcu_rp2040_register_t _SIO(0x140))
#define SPINLOCK17  (sif_mcu_rp2040_register_t _SIO(0x144))
#define SPINLOCK18  (sif_mcu_rp2040_register_t _SIO(0x148))
#define SPINLOCK19  (sif_mcu_rp2040_register_t _SIO(0x14c))
#define SPINLOCK20  (sif_mcu_rp2040_register_t _SIO(0x150))
#define SPINLOCK21  (sif_mcu_rp2040_register_t _SIO(0x154))
#define SPINLOCK22  (sif_mcu_rp2040_register_t _SIO(0x158))
#define SPINLOCK23  (sif_mcu_rp2040_register_t _SIO(0x15c))
#define SPINLOCK24  (sif_mcu_rp2040_register_t _SIO(0x160))
#define SPINLOCK25  (sif_mcu_rp2040_register_t _SIO(0x164))
#define SPINLOCK26  (sif_mcu_rp2040_register_t _SIO(0x168))
#define SPINLOCK27  (sif_mcu_rp2040_register_t _SIO(0x16c))
#define SPINLOCK28  (sif_mcu_rp2040_register_t _SIO(0x170))
#define SPINLOCK29  (sif_mcu_rp2040_register_t _SIO(0x174))
#define SPINLOCK30  (sif_mcu_rp2040_register_t _SIO(0x178))
#define SPINLOCK31  (sif_mcu_rp2040_register_t _SIO(0x17c))
#define SPINLOCK_ST (sif_mcu_rp2040_register_t _SIO(0x05c))

#endif	// SIF_MCU_RP2040_REGISTERS_H
