// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * syscall.h -- system call
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_SYSCALL_H
#define SIF_SYSCALL_H

typedef enum sif_syscall {
	SIF_SYSCALL_YIELD,
	SIF_SYSCALL_TOTAL,
} sif_syscall_t;

typedef enum sif_syscall_error {
	SIF_SYSCALL_ERROR_NONE,
	SIF_SYSCALL_ERROR_INVALID,
} sif_syscall_error_t;

extern sif_syscall_error_t (* const sif_syscalls[SIF_SYSCALL_TOTAL])(
	void * const arg);

sif_syscall_error_t sif_syscall_vaild(int syscall);

#endif	// SIF_SYSCALL_H
