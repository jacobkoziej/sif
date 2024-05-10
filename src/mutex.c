// SPDX-License-Identifier: MPL-2.0
/*
 * mutex.c -- mutual exclusion lock
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/mutex.h>

#include <string.h>

void sif_mutex_init(sif_mutex_t * const mutex)
{
	memset(mutex, 0, sizeof(*mutex));
}
