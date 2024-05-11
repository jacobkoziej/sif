// SPDX-License-Identifier: MPL-2.0
/*
 * syscall.h -- system call
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_SYSCALL_H
#define SIF_PRIVATE_SYSCALL_H

#include <sif/list.h>
#include <sif/sif.h>
#include <sif/syscall.h>
#include <sif/task.h>

extern sif_syscall_error_t (* const sif_syscalls[SIF_SYSCALL_TOTAL])(
	void * const arg);

static sif_syscall_error_t sif_syscall_mutex_lock(void * const arg);
static sif_syscall_error_t sif_syscall_task_add(void * const arg);
static sif_syscall_error_t sif_syscall_task_delete(void * const arg);
static sif_syscall_error_t sif_syscall_task_tick_delay(void * const arg);
static sif_syscall_error_t sif_syscall_yield(void * const arg);

static void sif_syscall_suspend(sif_core_t * const core,
	sif_list_t ** const			   list,
	sif_task_t * const			   task);

#endif	// SIF_PRIVATE_SYSCALL_H
