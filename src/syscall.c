// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * syscall.c -- system call
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/private/syscall.h>
#include <sif/syscall.h>

void (* const sif_syscalls[SIF_SYSCALL_TOTAL])(void * const arg) = {
	[SIF_SYSCALL_YIELD] = sif_syscall_yield,
};

static void sif_syscall_yield(void * const arg)
{
	(void) arg;

	// yield from task
}
