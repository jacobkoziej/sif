// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * task.h -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_TASK_H
#define SIF_PRIVATE_TASK_H

#include <sif/task.h>

extern void (* const sif_port_task_scheduler_start)(sif_task_stack_t *stack);

extern sif_task_stack_t *(* const sif_port_task_init_context)(
	sif_task_stack_t *stack, sif_task_function_t *func, void *arg);

static sif_task_error_t sif_task_add_task(
	sif_task_t * const task, const sif_task_config_t * const config);
static void sif_task_idle_task(void * const arg);
static void sif_task_idle_task_config(sif_task_config_t * const config);
static sif_task_error_t sif_task_init_stack(
	sif_task_stack_descriptor_t * const stack,
	const sif_task_config_t * const	    config);

#endif	// SIF_PRIVATE_TASK_H
