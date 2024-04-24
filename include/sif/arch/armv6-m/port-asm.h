// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.h -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ARCH_ARMV6_M_PORT_ASM_H
#define SIF_ARCH_ARMV6_M_PORT_ASM_H

#include <sif/arch/armv6-m/types.h>
#include <sif/syscall.h>
#include <sif/task.h>

sif_arch_armv6_m_word_t sif_arch_armv6_m_get_subtick_count(void);
void			sif_arch_armv6_m_init(void);
sif_task_stack_t       *sif_arch_armv6_m_init_context(
	      sif_task_stack_t *stack, sif_task_function_t func, void *arg);
void		    sif_arch_armv6_m_interrupt_disable(void);
void		    sif_arch_armv6_m_interrupt_enable(void);
void		    sif_arch_armv6_m_pendsv_set(void);
void		    sif_arch_armv6_m_pendsv_clear(void);
void		    sif_arch_armv6_m_scheduler_start(sif_task_stack_t *stack);
sif_syscall_error_t sif_arch_armv6_m_syscall(
	sif_syscall_t syscall, void * const arg);

#endif	// SIF_ARCH_ARMV6_M_PORT_ASM_H
