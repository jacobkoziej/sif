// SPDX-License-Identifier: MPL-2.0
/*
 * registers.s -- rp2040 registers
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.set SIO_BASE, 0xd0000000

	.set COREID, SIO_BASE + 0x00

	.set SPINLOCK14, SIO_BASE + 0x138
	.set SPINLOCK15, SIO_BASE + 0x13c
