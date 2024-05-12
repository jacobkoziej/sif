// SPDX-License-Identifier: MPL-2.0
/*
 * mutex.h -- mutual exclusion lock
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_PRIVATE_MUTEX_H
#define SIF_PRIVATE_MUTEX_H

#include <sif/mutex.h>
#include <sif/syscall.h>

static sif_mutex_error_t sif_mutex_syscall_dispatch(
	sif_syscall_t syscall, void * const arg);

#endif	// SIF_PRIVATE_MUTEX_H
