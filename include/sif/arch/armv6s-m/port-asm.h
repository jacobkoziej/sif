// SPDX-License-Identifier: MPL-2.0
/*
 * port-asm.h -- armv6s-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ARCH_ARMV6S_M_PORT_ASM_H
#define SIF_ARCH_ARMV6S_M_PORT_ASM_H

#include <sif/arch/armv6s-m/types.h>
#include <sif/syscall.h>
#include <sif/task.h>

void		  sif_arch_armv6s_m_handler_pendsv(void);
void		  sif_arch_armv6s_m_handler_svcall(sif_syscall_t syscall);
void		  sif_arch_armv6s_m_handler_systick(void);
void		  sif_arch_armv6s_m_init(void);
sif_task_stack_t *sif_arch_armv6s_m_init_context(
	sif_task_stack_t *stack, sif_task_function_t func, void *arg);
void		    sif_arch_armv6s_m_interrupt_disable(void);
void		    sif_arch_armv6s_m_interrupt_enable(void);
void		    sif_arch_armv6s_m_pendsv_set(void);
void		    sif_arch_armv6s_m_pendsv_clear(void);
void		    sif_arch_armv6s_m_scheduler_start(sif_task_stack_t *stack);
sif_syscall_error_t sif_arch_armv6s_m_syscall(
	sif_syscall_t syscall, void * const arg);
sif_arch_armv6s_m_word_t sif_arch_armv6s_m_systick_count_flag(void);
sif_arch_armv6s_m_word_t sif_arch_armv6s_m_systick_current_value(void);
void			 sif_arch_armv6s_m_wait_for_interrupt(void);

#endif	// SIF_ARCH_ARMV6S_M_PORT_ASM_H
