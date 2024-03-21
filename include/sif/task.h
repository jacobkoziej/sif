// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * task.h -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_TASK_H
#define SIF_TASK_H

#include <limits.h>
#include <stddef.h>

#define SIF_TASK_PRIORITY_MAXIMUM 0
#define SIF_TASK_PRIORITY_MINIMUM (UINT_MAX - 1)

typedef unsigned      sif_task_priority_t;
typedef unsigned char sif_task_stack_buffer_t;

typedef void(sif_task_function_t)(void * const arg);

typedef enum sif_task_error {
	SIF_TASK_ERROR_NONE,
	SIF_TASK_ERROR_PRIORITY,
	SIF_TASK_ERROR_STACK_SIZE,
	SIF_TASK_ERROR_TASK_COUNT,
} sif_task_error_t;

typedef struct sif_task_stack {
	sif_task_stack_buffer_t *sp;
	sif_task_stack_buffer_t *start;
	sif_task_stack_buffer_t *end;
} sif_task_stack_t;

typedef enum sif_task_state {
	SIF_TASK_STATE_ACTIVE,
	SIF_TASK_STATE_PENDING,
	SIF_TASK_STATE_SUSPENDED,
	SIF_TASK_STATE_DELETED,
} sif_task_state_t;

typedef struct sif_task {
	sif_task_state_t    state;
	sif_task_priority_t priority;
	sif_task_stack_t    stack;
	const char	   *name;
} sif_task_t;

typedef struct sif_task_config {
	const char		*name;
	sif_task_function_t	*func;
	void			*arg;
	sif_task_priority_t	 priority;
	sif_task_stack_buffer_t *stack;
	size_t			 stack_size;
} sif_task_config_t;

sif_task_error_t sif_task_create(const sif_task_config_t * const config);
sif_task_error_t sif_task_delete(void);

#endif	// SIF_TASK_H
