// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * syscall.h -- system call
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_SYSCALL_H
#define SIF_PRIVATE_SYSCALL_H

#include <sif/syscall.h>

extern sif_syscall_error_t (* const sif_syscalls[SIF_SYSCALL_TOTAL])(
	void * const arg);

static sif_syscall_error_t sif_syscall_task_add(void * const arg);
static sif_syscall_error_t sif_syscall_task_delete(void * const arg);
static sif_syscall_error_t sif_syscall_yield(void * const arg);

#endif	// SIF_PRIVATE_SYSCALL_H
