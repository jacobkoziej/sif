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
		[SIF_SYSCALL_TASK_ADD] = sif_syscall_task_add,
		[SIF_SYSCALL_YIELD]    = sif_syscall_yield,
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

	task->pid = sif.next_pid++;

	sif_list_append_back(sif.ready + task->priority, &task->list);

	sif_port_kernel_unlock();

	return SIF_SYSCALL_ERROR_NONE;
}

static sif_syscall_error_t sif_syscall_yield(void * const arg)
{
	(void) arg;

	// yield from task

	return SIF_SYSCALL_ERROR_NONE;
}
