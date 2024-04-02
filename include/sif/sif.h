// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * sif.h -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_SIF_H
#define SIF_SIF_H

#include <sif/config.h>
#include <sif/list.h>
#include <sif/task.h>

typedef struct sif_core {
	sif_task_t	   *running;
	sif_task_t	   *queued;
	sif_task_priority_t priority;
} sif_core_t;

typedef struct sif {
	sif_core_t     cores[SIF_CONFIG_CORES];
	sif_list_t    *ready[SIF_CONFIG_PRIORITY_LEVELS];
	sif_task_pid_t next_pid;
} sif_t;

extern sif_t sif;

void sif_systick(void);

#endif	// SIF_SIF_H
