// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * task.h -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_TASK_H
#define SIF_TASK_H

#include <sif/config.h>
#include <sif/list.h>

#include <limits.h>
#include <stddef.h>
#include <stdint.h>

typedef unsigned      sif_task_priority_t;
typedef unsigned      sif_task_cpu_mask_t;
typedef unsigned char sif_task_stack_t;
typedef uint64_t      sif_task_subticks_t;
typedef uint64_t      sif_task_ticks_t;
typedef uint64_t      sif_task_tid_t;

typedef void(sif_task_function_t)(void * const arg);

typedef enum sif_task_error {
	SIF_TASK_ERROR_NONE,
	SIF_TASK_ERROR_NOTHING_TO_SCHEDULE,
	SIF_TASK_ERROR_PRIORITY,
	SIF_TASK_ERROR_STACK_SIZE,
	SIF_TASK_ERROR_UNDEFINED,
} sif_task_error_t;

typedef struct sif_task_stack_descriptor {
	sif_task_stack_t *sp;
	sif_task_stack_t *start;
	sif_task_stack_t *end;
} sif_task_stack_descriptor_t;

typedef enum sif_task_state {
	SIF_TASK_STATE_ACTIVE,
	SIF_TASK_STATE_READY,
	SIF_TASK_STATE_SUSPENDED,
	SIF_TASK_STATE_DELETED,
} sif_task_state_t;

typedef struct sif_task_time {
	sif_task_ticks_t    ticks;
	sif_task_subticks_t subticks;
} sif_task_time_t;

typedef struct sif_task {
	sif_list_t		    list;
	sif_task_state_t	    state;
	sif_task_tid_t		    tid;
	sif_task_priority_t	    priority;
	sif_task_cpu_mask_t	    cpu_mask;
	sif_task_time_t		    times[SIF_CONFIG_CORES];
	sif_task_stack_descriptor_t stack;
} sif_task_t;

typedef struct sif_task_config {
	sif_task_function_t *func;
	void		    *arg;
	sif_task_priority_t  priority;
	sif_task_cpu_mask_t  cpu_mask;
	sif_task_stack_t    *stack;
	size_t		     stack_size;
} sif_task_config_t;

sif_task_error_t  sif_task_add(sif_task_t  *const task);
sif_task_stack_t *sif_task_context_switch(sif_task_stack_t * const sp);
sif_task_error_t  sif_task_init(
	 sif_task_t  *const task, const sif_task_config_t  *const config);
sif_task_error_t sif_task_create(const sif_task_config_t * const config);
sif_task_error_t sif_task_delete(void);
sif_task_error_t sif_task_scheduler_start(void);
void		 sif_task_systick(void);
void		 sif_task_reschedule(void);

#endif	// SIF_TASK_H
