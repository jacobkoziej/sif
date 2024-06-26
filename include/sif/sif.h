// SPDX-License-Identifier: MPL-2.0
/*
 * sif.h -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_SIF_H
#define SIF_SIF_H

#include <sif/config.h>
#include <sif/list.h>
#include <sif/port.h>
#include <sif/task.h>

typedef sif_port_word_t sif_word_t;

typedef struct sif_core {
	sif_task_t	   *running;
	sif_task_t	   *queued;
	sif_task_priority_t priority;
	sif_list_t	   *tick_delay[SIF_CONFIG_PRIORITY_LEVELS];
	sif_task_time_t	    idle_time;
	sif_task_time_t	    prev_time;
	sif_task_time_t	    system_time;
	sif_task_time_t	    system_time_offset;
	sif_task_time_t	    prev_count;
} sif_core_t;

typedef struct sif {
	sif_core_t	    cores[SIF_CONFIG_CORES];
	sif_list_t	   *ready[SIF_CONFIG_PRIORITY_LEVELS];
	sif_task_tid_t	    next_tid;
	sif_task_cpu_mask_t cpu_enabled;
} sif_t;

extern sif_t sif;

extern sif_port_word_t (* const sif_port_get_coreid)(void);
extern void (* const sif_port_kernel_lock)(void);
extern void (* const sif_port_kernel_unlock)(void);

void		  sif_init(void);
sif_task_stack_t *sif_pendsv(sif_task_stack_t * const sp);
sif_task_time_t	  sif_system_time(void);
void		  sif_systick(void);

#endif	// SIF_SIF_H
