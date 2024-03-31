// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port.c -- rp2040 port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/arch/armv6-m/port-asm.h>
#include <sif/config.h>
#include <sif/march/rp2040/port-asm.h>
#include <sif/march/rp2040/port.h>

void (* const sif_port_task_scheduler_start)(sif_task_stack_t *stack)
	= sif_march_rp2040_scheduler_start;

sif_task_stack_t *(* const sif_port_task_init_context)(
	sif_task_stack_t *stack, sif_task_function_t *func, void *arg)
	= sif_arch_armv6_m_init_context;

void (* const sif_port_kernel_lock)(void) = sif_march_rp2040_kernel_lock;

void (* const sif_port_kernel_unlock)(void) = sif_march_rp2040_kernel_unlock;

sif_syscall_error_t (* const sif_port_syscall)(
	sif_syscall_t syscall, void * const arg)
	= sif_arch_armv6_m_syscall;
