// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.h -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ARCH_ARMV6_M_PORT_ASM_H
#define SIF_ARCH_ARMV6_M_PORT_ASM_H

#include <sif/task.h>

sif_task_stack_buffer_t *sif_arch_armv6_m_init_stack(
    sif_task_stack_buffer_t *stack,
    sif_task_function_t	     func,
    void		    *arg);
void sif_arch_armv6_m_setup_nvic(void);

#endif	// SIF_ARCH_ARMV6_M_PORT_ASM_H
