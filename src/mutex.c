// SPDX-License-Identifier: MPL-2.0
/*
 * mutex.c -- mutual exclusion lock
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/mutex.h>
#include <sif/syscall.h>

#include <string.h>

void sif_mutex_init(sif_mutex_t * const mutex)
{
	memset(mutex, 0, sizeof(*mutex));
}

sif_mutex_error_t sif_mutex_lock(sif_mutex_t * const mutex)
{
	switch (sif_port_syscall(SIF_SYSCALL_MUTEX_LOCK, mutex)) {
		case SIF_SYSCALL_ERROR_NONE:
			return SIF_MUTEX_ERROR_NONE;

		case SIF_SYSCALL_ERROR_MUTEX_LOCKED:
			return SIF_MUTEX_LOCKED;

		default:
			return SIF_MUTEX_ERROR_UNDEFINED;
	}
}
