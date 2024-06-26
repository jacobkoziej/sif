// SPDX-License-Identifier: MPL-2.0
/*
 * task.h -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_TASK_H
#define SIF_PRIVATE_TASK_H

#include <sif/list.h>
#include <sif/port.h>
#include <sif/task.h>

#include <stdbool.h>

extern void (* const sif_port_interrupt_disable)(void);
extern void (* const sif_port_interrupt_enable)(void);
extern void (* const sif_port_pendsv_clear)(void);
extern void (* const sif_port_pendsv_set)(void);
extern void (* const sif_port_task_scheduler_start)(sif_task_stack_t *stack);
extern void (* const sif_port_wait_for_interrupt)(void);

extern sif_task_stack_t *(* const sif_port_task_init_context)(
	sif_task_stack_t *stack, sif_task_function_t *func, void *arg);

static sif_task_error_t sif_task_init_stack(
	sif_task_stack_descriptor_t * const stack,
	const sif_task_config_t * const	    config);
static bool sif_task_tick_delay_decrement(sif_list_t * const node);

#endif	// SIF_PRIVATE_TASK_H
