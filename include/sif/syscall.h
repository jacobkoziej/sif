// SPDX-License-Identifier: MPL-2.0
/*
 * syscall.h -- system call
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_SYSCALL_H
#define SIF_SYSCALL_H

typedef enum sif_syscall {
	SIF_SYSCALL_MUTEX_LOCK,
	SIF_SYSCALL_MUTEX_UNLOCK,
	SIF_SYSCALL_TASK_ADD,
	SIF_SYSCALL_TASK_DELETE,
	SIF_SYSCALL_TASK_TICK_DELAY,
	SIF_SYSCALL_YIELD,
	SIF_SYSCALL_TOTAL,
} sif_syscall_t;

typedef enum sif_syscall_error {
	SIF_SYSCALL_ERROR_NONE,
	SIF_SYSCALL_ERROR_INVALID,
	SIF_SYSCALL_ERROR_MUTEX_LOCKED,
	SIF_SYSCALL_ERROR_MUTEX_OWNER,
} sif_syscall_error_t;

extern sif_syscall_error_t (* const sif_port_syscall)(
	sif_syscall_t syscall, void * const arg);

sif_syscall_error_t sif_syscall_vaild(int syscall);

#endif	// SIF_SYSCALL_H
