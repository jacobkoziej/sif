// SPDX-License-Identifier: MPL-2.0
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
#include <string.h>

sif_task_error_t sif_task_add(sif_task_t * const task)
{
	return sif_port_syscall(SIF_SYSCALL_TASK_ADD, task)
		? SIF_TASK_ERROR_UNDEFINED
		: SIF_TASK_ERROR_NONE;
}

sif_task_stack_t *sif_task_context_switch(sif_task_stack_t * const sp)
{
	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;
	sif_task_t	  *task	  = core->running;

	task->stack.sp = sp;
	task->state    = SIF_TASK_STATE_READY;

	sif_task_time_t * const time	  = task->times + coreid;
	sif_task_time_t * const prev_time = &core->prev_time;

	sif_task_update_time(prev_time, time);

	sif_list_t ** const ready = sif.ready + task->priority;
	sif_list_t * const  list  = task->lists + SIF_TASK_LIST_READY;

	sif_port_kernel_lock();
	sif_list_append_back(ready, list);
	sif_port_kernel_unlock();

	task = core->queued;

	task->state = SIF_TASK_STATE_ACTIVE;

	core->running  = task;
	core->queued   = NULL;
	core->priority = task->priority;

	return task->stack.sp;
}

sif_task_error_t sif_task_init(
	sif_task_t * const task, const sif_task_config_t * const config)
{
	if (config->priority >= SIF_CONFIG_PRIORITY_LEVELS)
		return SIF_TASK_ERROR_PRIORITY;

	memset(task, 0, sizeof(*task));

	sif_task_error_t error;

	error = sif_task_init_stack(&task->stack, config);

	if (error != SIF_TASK_ERROR_NONE) return error;

	for (size_t i = 0; i < SIF_TASK_LISTS; i++)
		sif_list_node_init(task->lists + i);

	task->priority = config->priority;
	task->cpu_mask = config->cpu_mask;

	return SIF_TASK_ERROR_NONE;
}

sif_task_error_t sif_task_delete(void)
{
	sif_port_syscall(SIF_SYSCALL_TASK_DELETE, NULL);

	return SIF_TASK_ERROR_NONE;
}

void sif_task_idle(void)
{
	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;
	sif_task_t * const task	  = core->running;

	sif_task_time_t	       *time;
	sif_task_time_t * const prev_time = &core->prev_time;

	if (!task) {
		time = &core->idle_time;
		goto skip_idle_enter;
	}

	sif_list_t ** const ready = sif.ready + task->priority;
	sif_list_t * const  list  = task->lists + SIF_TASK_LIST_READY;

	sif_port_kernel_lock();
	sif_list_append_back(ready, list);
	sif_port_kernel_unlock();

	core->running  = NULL;
	core->priority = SIF_CONFIG_PRIORITY_LEVELS - 1;

	time = task->times + coreid;

skip_idle_enter:;
	sif_task_update_time(prev_time, time);

	sif_port_wait_for_interrupt();
	sif_port_pendsv_set();
}

sif_task_error_t sif_task_scheduler_start(void)
{
	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;

	sif_port_interrupt_disable();

	// here we trick sif_task_reschedule() to give us
	// the highest priority task available so that we
	// can bootstrap the scheduler
	sif_port_kernel_lock();
	sif.cpu_enabled |= 1 << coreid;
	sif_port_kernel_unlock();
	core->priority = SIF_CONFIG_PRIORITY_LEVELS - 1;
	sif_task_reschedule();
	sif_port_pendsv_clear();

	sif_task_t * const task = core->queued;

	if (!task) return SIF_TASK_ERROR_NOTHING_TO_SCHEDULE;

	task->state = SIF_TASK_STATE_ACTIVE;

	core->running	= task;
	core->queued	= NULL;
	core->priority	= task->priority;
	core->prev_time = sif_port_systick_current_value();

	sif_port_task_scheduler_start(task->stack.sp);

	return SIF_TASK_ERROR_UNDEFINED;
}

void sif_task_systick(void)
{
	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;
	sif_task_t * const task	  = core->running;

	if (!task) return;

	sif_task_time_t * const time	  = task->times + coreid;
	sif_task_time_t * const prev_time = &core->prev_time;

	sif_task_update_time(prev_time, time);
}

void sif_task_reschedule(void)
{
	sif_task_t *next_task = NULL;

	const sif_word_t	  coreid   = sif_port_get_coreid();
	sif_core_t * const	  core	   = sif.cores + coreid;
	const sif_task_cpu_mask_t cpu_mask = 1 << coreid;

	sif_port_kernel_lock();

	if (!(sif.cpu_enabled & cpu_mask)) {
		sif_port_kernel_unlock();
		return;
	}

	sif_task_priority_t priority;
	for (priority = 0; priority < SIF_CONFIG_PRIORITY_LEVELS; priority++) {
		if (!sif.ready[priority]) continue;

		if (priority > core->priority) break;

		sif_list_t **list = sif.ready + priority;

		sif_list_t *node = *list;

		do {
			sif_task_t * const task = SIF_TASK_LIST2TASK(node);

			if (!(task->cpu_mask & cpu_mask)) {
				node = node->next;
				continue;
			}

			sif_list_remove_next(list, node);
			next_task = task;

			goto found;
		} while (*list && *list != node);
	}

found:
	sif_port_kernel_unlock();

	if (!next_task) {
		// enter idle
		if (!core->running) sif_port_pendsv_set();

		return;
	}

	if (core->queued) {
		sif_task_t * const  task  = core->queued;
		sif_list_t ** const ready = sif.ready + task->priority;
		sif_list_t * const  list  = task->lists + SIF_TASK_LIST_READY;

		sif_port_kernel_lock();
		sif_list_prepend_front(ready, list);
		sif_port_kernel_unlock();
	}

	core->queued = next_task;

	sif_port_pendsv_set();
}

void sif_task_update_time(
	sif_task_time_t * const prev_time, sif_task_time_t * const time)
{
	const sif_task_time_t current_count = sif_port_systick_current_value();

	*time += (*prev_time - current_count + *SIF_PORT_SYSTICK_RELOAD)
		% *SIF_PORT_SYSTICK_RELOAD;

	*prev_time = current_count;
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
