// SPDX-License-Identifier: MPL-2.0
/*
 * task.h -- task management
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_TASK_H
#define SIF_TASK_H

#include <sif/config.h>
#include <sif/list.h>

#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SIF_TASK_LIST2TASK(x) SIF_LIST_CONTAINER_OF(x, sif_task_t, list)

typedef unsigned      sif_task_priority_t;
typedef unsigned      sif_task_cpu_mask_t;
typedef unsigned char sif_task_stack_t;
typedef unsigned      sif_task_tick_delay_t;
typedef uint64_t      sif_task_tid_t;
typedef uint64_t      sif_task_time_t;

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

typedef struct sif_task {
	sif_list_t		    list;
	sif_task_state_t	    state;
	sif_task_tid_t		    tid;
	sif_task_priority_t	    priority;
	sif_task_priority_t	    base_priority;
	sif_task_cpu_mask_t	    cpu_mask;
	sif_task_time_t		    times[SIF_CONFIG_CORES];
	sif_task_time_t		    suspend_time;
	sif_task_tick_delay_t	    tick_delay;
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

sif_task_error_t sif_task_add(sif_task_t * const task);
bool sif_task_compare_suspend_time(sif_list_t * const a, sif_list_t * const b);
sif_task_stack_t *sif_task_context_switch(sif_task_stack_t * const sp);
sif_task_error_t  sif_task_init(
	 sif_task_t  *const task, const sif_task_config_t  *const config);
sif_task_error_t sif_task_create(const sif_task_config_t * const config);
sif_task_error_t sif_task_delete(void);
void		 sif_task_idle(sif_task_stack_t		    *const sp);
void		 sif_task_reschedule(void);
sif_task_error_t sif_task_scheduler_start(void);
void		 sif_task_systick(void);
sif_task_error_t sif_task_tick_delay(sif_task_tick_delay_t tick_delay);
void		 sif_task_update_time(
		    sif_task_time_t		*const prev_time, sif_task_time_t		   *const time);

#endif	// SIF_TASK_H
