// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * task.c -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/config.h>
#include <sif/private/task.h>
#include <sif/sif.h>
#include <sif/task.h>

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

sif_task_error_t sif_task_create(const sif_task_config_t * const config)
{
	size_t * const task_count = &sif.task_count;

	if (*task_count >= SIF_CONFIG_MAXIMUM_TASKS - 1)
		return SIF_TASK_ERROR_TASK_COUNT;

	if (config->priority > SIF_TASK_PRIORITY_MINIMUM)
		return SIF_TASK_ERROR_PRIORITY;

	sif_task_t * const task = sif.tasks + (*task_count)++;

	sif_task_error_t error;

	error = sif_task_add_task(task, config);

	if (error != SIF_TASK_ERROR_NONE) return error;

	return SIF_TASK_ERROR_NONE;
}

sif_task_error_t sif_task_delete(void)
{
	// TODO: svc to delete
	while (true) continue;

	return SIF_TASK_ERROR_NONE;
}

sif_task_error_t sif_task_scheduler_start(void)
{
	size_t * const	   task_count = &sif.task_count;
	sif_task_t * const task	      = sif.tasks + (*task_count)++;

	sif_task_error_t  error;
	sif_task_config_t config = {0};

	sif_task_idle_task_config(&config);

	error = sif_task_add_task(task, &config);

	if (error != SIF_TASK_ERROR_NONE) return error;

	task->state = SIF_TASK_STATE_ACTIVE;
	sif_port_task_scheduler_start(task->stack.sp);

	return SIF_TASK_ERROR_UNDEFINED;
}

static sif_task_error_t sif_task_add_task(
	sif_task_t * const task, const sif_task_config_t * const config)
{
	size_t		stack_size   = config->stack_size;
	const uintptr_t stack_buffer = (uintptr_t) config->stack;

	if (stack_size <= SIF_CONFIG_STACK_ALIGNMENT_MASK)
		return SIF_TASK_ERROR_STACK_SIZE;

#if (SIF_CONFIG_STACK_GROWTH_DIRECTION < 0)
	const uintptr_t stack_start_raw = stack_buffer + stack_size - 1;

	const uintptr_t stack_start = stack_start_raw
		& ~((uintptr_t) SIF_CONFIG_STACK_ALIGNMENT_MASK);

	const uintptr_t difference = stack_start_raw - stack_start;

	stack_size -= difference;

	const uintptr_t stack_end = stack_start - stack_size + 1;
#else	// SIF_CONFIG_STACK_GROWTH_DIRECTION
	const uintptr_t stack_start_raw = stack_buffer;

	uintptr_t stack_start = stack_start_raw
		& ~((uintptr_t) SIF_CONFIG_STACK_ALIGNMENT_MASK);

	if (stack_start < stack_start_raw)
		stack_start += SIF_CONFIG_STACK_ALIGNMENT_MASK + 1;

	const uintptr_t difference = stack_start - stack_start_raw;

	stack_size -= difference;

	const uintptr_t stack_end = stack_start + stack_size - 1;
#endif	// SIF_CONFIG_STACK_GROWTH_DIRECTION

	if (stack_size < SIF_CONFIG_MINIMUM_STACK_SIZE)
		return SIF_TASK_ERROR_STACK_SIZE;

	const sif_task_stack_descriptor_t stack
		= (sif_task_stack_descriptor_t){
			.sp = sif_port_task_init_stack(
				(sif_task_stack_t *) stack_start,
				config->func,
				config->arg),
			.start = (sif_task_stack_t *) stack_start,
			.end   = (sif_task_stack_t *) stack_end,
		};

	*task = (sif_task_t){
		.state	  = SIF_TASK_STATE_PENDING,
		.priority = config->priority,
		.stack	  = stack,
		.name	  = config->name,
	};

	return SIF_TASK_ERROR_NONE;
}

static void sif_task_idle_task(void * const arg)
{
	(void) arg;

	while (true) continue;
}

static void sif_task_idle_task_config(sif_task_config_t * const config)
{
	static sif_task_stack_t stack[SIF_CONFIG_MINIMUM_STACK_SIZE * 2];

	*config = (sif_task_config_t){
		.name	    = "idle",
		.func	    = sif_task_idle_task,
		.arg	    = NULL,
		.priority   = SIF_TASK_PRIORITY_MINIMUM + 1,
		.stack	    = stack,
		.stack_size = sizeof(stack),
	};
}

static sif_task_error_t sif_task_init_stack(
	sif_task_stack_descriptor_t * const stack,
	const sif_task_config_t * const	    config)
{
	size_t stack_size = config->stack_size;

	if (stack_size < SIF_CONFIG_MINIMUM_STACK_SIZE)
		return SIF_TASK_ERROR_STACK_SIZE;

	const uintptr_t stack_buffer = (uintptr_t) config->stack;

#if (SIF_CONFIG_STACK_GROWTH_DIRECTION < 0)
	const uintptr_t stack_start_raw = stack_buffer + stack_size - 1;

	const uintptr_t stack_start = stack_start_raw
		& ~((uintptr_t) SIF_CONFIG_STACK_ALIGNMENT_MASK);

	const uintptr_t difference = stack_start_raw - stack_start;

	stack_size -= difference;

	const uintptr_t stack_end = stack_start - stack_size + 1;
#else	// SIF_CONFIG_STACK_GROWTH_DIRECTION
	const uintptr_t stack_start_raw = stack_buffer;

	uintptr_t stack_start = stack_start_raw
		& ~((uintptr_t) SIF_CONFIG_STACK_ALIGNMENT_MASK);

	if (stack_start < stack_start_raw)
		stack_start += SIF_CONFIG_STACK_ALIGNMENT_MASK + 1;

	const uintptr_t difference = stack_start - stack_start_raw;

	stack_size -= difference;

	const uintptr_t stack_end = stack_start + stack_size - 1;
#endif	// SIF_CONFIG_STACK_GROWTH_DIRECTION

	*stack = (sif_task_stack_descriptor_t){
		.sp
		= sif_port_task_init_context((sif_task_stack_t *) stack_start,
			config->func,
			config->arg),
		.start = (sif_task_stack_t *) stack_start,
		.end   = (sif_task_stack_t *) stack_end,
	};

	return SIF_TASK_ERROR_NONE;
}
