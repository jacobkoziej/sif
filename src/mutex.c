// SPDX-License-Identifier: MPL-2.0
/*
 * mutex.c -- mutual exclusion lock
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/mutex.h>
#include <sif/private/mutex.h>
#include <sif/syscall.h>

#include <string.h>

void sif_mutex_init(sif_mutex_t * const mutex)
{
	memset(mutex, 0, sizeof(*mutex));
}

sif_mutex_error_t sif_mutex_lock(sif_mutex_t * const mutex)
{
	return sif_mutex_syscall_dispatch(SIF_SYSCALL_MUTEX_LOCK, mutex);
}

sif_mutex_error_t sif_mutex_trylock(sif_mutex_t * const mutex)
{
	return sif_mutex_syscall_dispatch(SIF_SYSCALL_MUTEX_TRYLOCK, mutex);
}

sif_mutex_error_t sif_mutex_unlock(sif_mutex_t * const mutex)
{
	return sif_mutex_syscall_dispatch(SIF_SYSCALL_MUTEX_UNLOCK, mutex);
}

static sif_mutex_error_t sif_mutex_syscall_dispatch(
	sif_syscall_t syscall, void * const arg)
{
	switch (sif_port_syscall(syscall, arg)) {
		case SIF_SYSCALL_ERROR_NONE:
			return SIF_MUTEX_ERROR_NONE;

		case SIF_SYSCALL_ERROR_MUTEX_LOCKED:
			return SIF_MUTEX_ERROR_LOCKED;

		case SIF_SYSCALL_ERROR_MUTEX_OWNER:
			return SIF_MUTEX_ERROR_OWNER;

		default:
			return SIF_MUTEX_ERROR_UNDEFINED;
	}
}
