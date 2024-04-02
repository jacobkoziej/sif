// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * task.c -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/config.h>
#include <sif/list.h>
#include <sif/private/task.h>
#include <sif/sif.h>
#include <sif/syscall.h>
#include <sif/task.h>

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

sif_task_error_t sif_task_add(sif_task_t * const task)
{
	return sif_port_syscall(SIF_SYSCALL_TASK_ADD, task)
		? SIF_TASK_ERROR_UNDEFINED
		: SIF_TASK_ERROR_NONE;
}

sif_task_error_t sif_task_init(
	sif_task_t * const task, const sif_task_config_t * const config)
{
	if (config->priority >= SIF_CONFIG_PRIORITY_LEVELS)
		return SIF_TASK_ERROR_PRIORITY;

	sif_task_error_t error;

	error = sif_task_init_stack(&task->stack, config);

	if (error != SIF_TASK_ERROR_NONE) return error;

	sif_list_node_init(&task->list);

	task->priority = config->priority;
	task->cpu_mask = config->cpu_mask;

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
	// sif_port_task_scheduler_start(task->stack.sp);

	return SIF_TASK_ERROR_UNDEFINED;
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
