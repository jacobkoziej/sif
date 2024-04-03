// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * sif.h -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_SIF_H
#define SIF_PRIVATE_SIF_H

#include <sif/port.h>
#include <sif/sif.h>

extern sif_port_word_t (* const sif_port_get_coreid)(void);
extern void (* const sif_port_init)(void);

#endif	// SIF_PRIVATE_SIF_H
