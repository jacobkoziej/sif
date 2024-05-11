// SPDX-License-Identifier: MPL-2.0
/*
 * syscall.c -- system call
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/atomic.h>
#include <sif/mutex.h>
#include <sif/private/syscall.h>
#include <sif/sif.h>
#include <sif/syscall.h>
#include <sif/task.h>

sif_syscall_error_t (* const sif_syscalls[SIF_SYSCALL_TOTAL])(void * const arg)
	= {
		[SIF_SYSCALL_MUTEX_LOCK]      = sif_syscall_mutex_lock,
		[SIF_SYSCALL_MUTEX_UNLOCK]    = sif_syscall_mutex_unlock,
		[SIF_SYSCALL_TASK_ADD]	      = sif_syscall_task_add,
		[SIF_SYSCALL_TASK_DELETE]     = sif_syscall_task_delete,
		[SIF_SYSCALL_TASK_TICK_DELAY] = sif_syscall_task_tick_delay,
		[SIF_SYSCALL_YIELD]	      = sif_syscall_yield,
};

sif_syscall_error_t sif_syscall_vaild(int syscall)
{
	return ((syscall >= 0) && (syscall < SIF_SYSCALL_TOTAL))
		? SIF_SYSCALL_ERROR_NONE
		: SIF_SYSCALL_ERROR_INVALID;
}

static sif_syscall_error_t sif_syscall_mutex_lock(void * const arg)
{
	sif_mutex_t * const mutex = arg;

	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;
	sif_task_t	  *task	  = core->running;

	sif_syscall_error_t error = SIF_SYSCALL_ERROR_NONE;

	while (sif_port_atomic_test_and_set(&mutex->lock)) continue;

	if (!mutex->owner) {
		mutex->owner = task;
		goto unlock;
	}

	if (mutex->owner == task) {
		error = SIF_SYSCALL_ERROR_MUTEX_LOCKED;
		goto unlock;
	}

	sif_list_t ** const list = mutex->waiting + task->priority;

	sif_syscall_suspend(core, list, task);

unlock:
	mutex->lock = 0;

	return error;
}

static sif_syscall_error_t sif_syscall_mutex_unlock(void * const arg)
{
	sif_mutex_t * const mutex = arg;

	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;
	sif_task_t	  *task	  = core->running;

	sif_syscall_error_t error = SIF_SYSCALL_ERROR_NONE;

	while (sif_port_atomic_test_and_set(&mutex->lock)) continue;

	if (mutex->owner != task) {
		error = SIF_SYSCALL_ERROR_MUTEX_OWNER;
		goto unlock;
	}

	for (sif_task_priority_t priority = 0;
		priority < SIF_CONFIG_PRIORITY_LEVELS;
		priority++) {
		sif_list_t **waiting = mutex->waiting + priority;

		if (!*waiting) continue;

		sif_list_t *node = *waiting;
		sif_list_remove_next(waiting, node);

		mutex->owner = SIF_TASK_LIST2TASK(node);

		sif_list_t **ready = sif.ready + priority;
		sif_list_merge_sorted(
			ready, &node, sif_task_compare_suspend_time);

		goto unlock;
	}

	mutex->owner = NULL;

unlock:
	mutex->lock = 0;

	return error;
}

static sif_syscall_error_t sif_syscall_task_add(void * const arg)
{
	sif_task_t * const task = arg;

	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;

	task->state = SIF_TASK_STATE_READY;

	sif_list_t ** const list = sif.ready + task->priority;
	sif_list_t * const  node = &task->list;

	sif_port_kernel_lock();

	task->tid	   = sif.next_tid++;
	task->suspend_time = sif_system_time() + core->system_time_offset;

	sif_list_append_back(list, node);

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

	core->running  = NULL;
	core->priority = SIF_CONFIG_PRIORITY_LEVELS - 1;

	return SIF_SYSCALL_ERROR_NONE;
}

static sif_syscall_error_t sif_syscall_task_tick_delay(void * const arg)
{
	const sif_task_tick_delay_t * const tick_delay = arg;

	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;
	sif_task_t	  *task	  = core->running;

	task->tick_delay = *tick_delay;

	sif_list_t ** const list = core->tick_delay + task->priority;

	sif_syscall_suspend(core, list, task);

	return SIF_SYSCALL_ERROR_NONE;
}

static sif_syscall_error_t sif_syscall_yield(void * const arg)
{
	(void) arg;

	// yield from task

	return SIF_SYSCALL_ERROR_NONE;
}

static void sif_syscall_suspend(sif_core_t * const core,
	sif_list_t ** const			   list,
	sif_task_t * const			   task)
{
	sif_list_t * const node = &task->list;

	sif_list_append_back(list, node);

	task->state	   = SIF_TASK_STATE_SUSPENDED;
	task->suspend_time = sif_system_time() + core->system_time_offset;

	core->priority = SIF_CONFIG_PRIORITY_LEVELS - 1;
}
