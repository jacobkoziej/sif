// SPDX-License-Identifier: MPL-2.0
/*
 * port-asm.h -- rp2040 port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_MARCH_RP2040_PORT_ASM_H
#define SIF_MARCH_RP2040_PORT_ASM_H

#include <sif/arch/armv6-m/types.h>
#include <sif/task.h>

typedef sif_arch_armv6_m_word_t sif_port_word_t;
typedef sif_port_word_t		sif_port_atomic_t;

sif_port_word_t	  sif_march_rp2040_get_coreid(void);
void		  sif_march_rp2040_init(void);
void		  sif_march_rp2040_kernel_lock(void);
void		  sif_march_rp2040_kernel_unlock(void);
void		  sif_march_rp2040_scheduler_start(sif_task_stack_t *stack);
sif_port_atomic_t sif_march_rp2040_test_and_set(sif_port_atomic_t *var);

#endif	// SIF_MARCH_RP2040_PORT_ASM_H
