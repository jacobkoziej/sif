// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * sif.h -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_SIF_H
#define SIF_PRIVATE_SIF_H

#include <sif/sif.h>

extern void (* const sif_port_kernel_lock)(void);
extern void (* const sif_port_kernel_unlock)(void);

#endif	// SIF_PRIVATE_SIF_H
