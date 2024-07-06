// SPDX-License-Identifier: MPL-2.0
/*
 * port.c -- rp2040 port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/arch/armv6s-m/port-asm.h>
#include <sif/arch/armv6s-m/port.h>
#include <sif/config.h>
#include <sif/mcu/rp2040/port-asm.h>
#include <sif/mcu/rp2040/port.h>

const sif_port_word_t * const SIF_PORT_SYSTICK_RELOAD
	= &SIF_ARCH_ARMV6_M_SYST_RVR_RELOAD;

sif_port_atomic_t (* const sif_port_atomic_test_and_set)(
	sif_port_atomic_t *var)
	= sif_mcu_rp2040_test_and_set;

sif_port_word_t (* const sif_port_get_coreid)(void)
	= sif_mcu_rp2040_get_coreid;

sif_port_word_t (* const sif_port_systick_count_flag)(void)
	= sif_arch_armv6s_m_systick_count_flag;

sif_port_word_t (* const sif_port_systick_current_value)(void)
	= sif_arch_armv6s_m_systick_current_value;

void (* const sif_port_init)(void) = sif_mcu_rp2040_init;

void (* const sif_port_interrupt_disable)(void)
	= sif_arch_armv6s_m_interrupt_disable;

void (* const sif_port_interrupt_enable)(void)
	= sif_arch_armv6s_m_interrupt_enable;

void (* const sif_port_kernel_lock)(void) = sif_mcu_rp2040_kernel_lock;

void (* const sif_port_kernel_unlock)(void) = sif_mcu_rp2040_kernel_unlock;

void (* const sif_port_pendsv_set)(void) = sif_arch_armv6s_m_pendsv_set;

void (* const sif_port_pendsv_clear)(void) = sif_arch_armv6s_m_pendsv_clear;

sif_syscall_error_t (* const sif_port_syscall)(
	sif_syscall_t syscall, void * const arg)
	= sif_arch_armv6s_m_syscall;

sif_task_stack_t *(* const sif_port_task_init_context)(
	sif_task_stack_t *stack, sif_task_function_t *func, void *arg)
	= sif_arch_armv6s_m_init_context;

void (* const sif_port_task_scheduler_start)(sif_task_stack_t *stack)
	= sif_mcu_rp2040_scheduler_start;

void (* const sif_port_wait_for_interrupt)(void)
	= sif_arch_armv6s_m_wait_for_interrupt;
