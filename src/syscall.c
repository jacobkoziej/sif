// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * syscall.c -- system call
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/private/syscall.h>
#include <sif/sif.h>
#include <sif/syscall.h>
#include <sif/task.h>

sif_syscall_error_t (* const sif_syscalls[SIF_SYSCALL_TOTAL])(void * const arg)
	= {
		[SIF_SYSCALL_TASK_ADD]	  = sif_syscall_task_add,
		[SIF_SYSCALL_TASK_DELETE] = sif_syscall_task_delete,
		[SIF_SYSCALL_YIELD]	  = sif_syscall_yield,
};

sif_syscall_error_t sif_syscall_vaild(int syscall)
{
	return ((syscall >= 0) && (syscall < SIF_SYSCALL_TOTAL))
		? SIF_SYSCALL_ERROR_NONE
		: SIF_SYSCALL_ERROR_INVALID;
}

static sif_syscall_error_t sif_syscall_task_add(void * const arg)
{
	sif_task_t * const task = arg;

	task->state = SIF_TASK_STATE_READY;

	sif_port_kernel_lock();

	task->tid = sif.next_tid++;

	sif_list_append_back(sif.ready + task->priority, &task->list);

	sif_port_kernel_unlock();

	return SIF_SYSCALL_ERROR_NONE;
}

static sif_syscall_error_t sif_syscall_task_delete(void * const arg)
{
	(void) arg;

	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;
	sif_task_t	  *task	  = core->running;

	sif_task_time_t * const time	  = task->times + coreid;
	sif_task_time_t * const prev_time = &core->prev_time;

	sif_task_update_time(prev_time, time);

	task->state = SIF_TASK_STATE_DELETED;

	task = core->queued;

	core->running  = NULL;
	core->queued   = NULL;
	core->priority = SIF_CONFIG_PRIORITY_LEVELS - 1;

	if (task) {
		sif_port_kernel_lock();
		sif_list_prepend_front(
			sif.ready + task->priority, &task->list);
		sif_port_kernel_unlock();
	}

	// we reschedule on exit from syscall dispatch

	return SIF_SYSCALL_ERROR_NONE;
}

static sif_syscall_error_t sif_syscall_yield(void * const arg)
{
	(void) arg;

	// yield from task

	return SIF_SYSCALL_ERROR_NONE;
}
