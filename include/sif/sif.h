// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * sif.h -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_SIF_H
#define SIF_SIF_H

#include <sif/config.h>
#include <sif/task.h>

typedef struct sif {
	sif_task_t tasks[SIF_CONFIG_MAXIMUM_TASKS];
	size_t	   task_count;
} sif_t;

extern sif_t sif;

void sif_systick(void);

#endif	// SIF_SIF_H
