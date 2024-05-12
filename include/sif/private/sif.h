// SPDX-License-Identifier: MPL-2.0
/*
 * sif.h -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_SIF_H
#define SIF_PRIVATE_SIF_H

#include <sif/sif.h>

extern const sif_port_word_t * const SIF_PORT_SYSTICK_RELOAD;

extern void (* const sif_port_init)(void);
extern sif_port_word_t (* const sif_port_systick_count_flag)(void);
extern sif_port_word_t (* const sif_port_systick_current_value)(void);

#endif	// SIF_PRIVATE_SIF_H
