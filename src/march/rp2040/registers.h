// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * registers.h -- rp2040 registers
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_MARCH_RP2040_REGISTERS_H
#define SIF_MARCH_RP2040_REGISTERS_H

#define SIF_MARCH_RP2040_REGISTER_SIO(X)                                 \
	(*(volatile unsigned long *) (SIF_MARCH_RP2040_REGISTER_SIO_BASE \
	    + (X)))

#define SIF_MARCH_RP2040_REGISTER_SIO_BASE 0xd0000000

#define SIF_MARCH_RP2040_REGISTER_SPINLOCK14 \
	SIF_MARCH_RP2040_REGISTER_SIO(0x138)
#define SIF_MARCH_RP2040_REGISTER_SPINLOCK15 \
	SIF_MARCH_RP2040_REGISTER_SIO(0x13c)

#endif	// SIF_MARCH_RP2040_REGISTERS_H
