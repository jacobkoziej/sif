// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * task.h -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_TASK_H
#define SIF_PRIVATE_TASK_H

#include <sif/list.h>
#include <sif/task.h>

#define SIF_TASK_LIST2TASK(x) SIF_LIST_CONTAINER_OF(x, sif_task_t, list)

extern void (* const sif_port_interrupt_disable)(void);
extern void (* const sif_port_interrupt_enable)(void);
extern void (* const sif_port_pendsv_clear)(void);
extern void (* const sif_port_pendsv_set)(void);
extern void (* const sif_port_task_scheduler_start)(sif_task_stack_t *stack);

extern sif_task_stack_t *(* const sif_port_task_init_context)(
	sif_task_stack_t *stack, sif_task_function_t *func, void *arg);

static sif_task_error_t sif_task_init_stack(
	sif_task_stack_descriptor_t * const stack,
	const sif_task_config_t * const	    config);

#endif	// SIF_PRIVATE_TASK_H