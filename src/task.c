// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * task.c -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/config.h>
#include <sif/task.h>

#include <stddef.h>

static struct {
	sif_task_t tasks[SIF_CONFIG_MAXIMUM_TASKS];
	size_t	   task_count;
} sif;

sif_task_error_t sif_task_create(sif_task_config_t * const config)
{
	size_t * const task_count = &sif.task_count;

	if (*task_count >= SIF_CONFIG_MAXIMUM_TASKS - 1)
		return SIF_TASK_ERROR_TASK_COUNT;

	sif_task_t * const task = sif.tasks + (*task_count)++;

	*task = (sif_task_t){
	    .state    = SIF_TASK_STATE_SUSPENDED,
	    .priority = config->priority,
	    .stack    = config->stack,
	    .name     = config->name,
	};

	return SIF_TASK_ERROR_NONE;
}
