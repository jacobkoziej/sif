// SPDX-License-Identifier: MPL-2.0
/*
 * mutex.h -- mutual exclusion lock
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_MUTEX_H
#define SIF_MUTEX_H

#include <sif/atomic.h>
#include <sif/config.h>
#include <sif/list.h>
#include <sif/task.h>

typedef enum sif_mutex_error {
	SIF_MUTEX_ERROR_NONE,
	SIF_MUTEX_ERROR_LOCKED,
	SIF_MUTEX_ERROR_OWNER,
	SIF_MUTEX_ERROR_UNDEFINED,
} sif_mutex_error_t;

typedef struct sif_mutex {
	sif_atomic_t lock;
	sif_task_t  *owner;
	sif_list_t  *waiting[SIF_CONFIG_PRIORITY_LEVELS];
} sif_mutex_t;

void		  sif_mutex_init(sif_mutex_t		  *const mutex);
sif_mutex_error_t sif_mutex_lock(sif_mutex_t * const mutex);
sif_mutex_error_t sif_mutex_trylock(sif_mutex_t * const mutex);
sif_mutex_error_t sif_mutex_unlock(sif_mutex_t * const mutex);

#endif	// SIF_MUTEX_H
