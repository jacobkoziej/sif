// SPDX-License-Identifier: MPL-2.0
/*
 * sif.c -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/private/sif.h>
#include <sif/sif.h>
#include <sif/task.h>

sif_t sif;

void sif_init(void)
{
	sif_port_init();
}

sif_task_stack_t *sif_pendsv(sif_task_stack_t * const sp)
{
	const sif_word_t   coreid = sif_port_get_coreid();
	sif_core_t * const core	  = sif.cores + coreid;

	if (!core->running) {
		if (core->queued) {
			sif_task_time_t * const time	  = &core->idle_time;
			sif_task_time_t * const prev_time = &core->prev_time;

			sif_task_update_time(prev_time, time);

			sif_task_t * const task = core->queued;

			task->state = SIF_TASK_STATE_ACTIVE;

			core->running  = task;
			core->queued   = NULL;
			core->priority = task->priority;

			return task->stack.sp;
		}

		sif_task_idle(sp);
		return sp;
	}

	if (!core->queued) {
		sif_task_t * const task = core->running;

		if (task->state == SIF_TASK_STATE_ACTIVE) return sp;

		sif_task_idle(sp);
		return sp;
	}

	return sif_task_context_switch(sp);
}

sif_task_time_t sif_system_time(void)
{
	const sif_word_t	coreid	    = sif_port_get_coreid();
	sif_core_t * const	core	    = sif.cores + coreid;
	sif_task_time_t * const system_time = &core->system_time;
	sif_task_time_t * const prev_count  = &core->prev_count;

	const sif_task_time_t current_count = sif_port_systick_current_value();

	if (sif_port_systick_count_flag()) {
		*system_time += *prev_count;
		*prev_count   = *SIF_PORT_SYSTICK_RELOAD;
	}

	*system_time
		+= (*prev_count - current_count + *SIF_PORT_SYSTICK_RELOAD + 1)
		% (*SIF_PORT_SYSTICK_RELOAD + 1);

	*prev_count = current_count;

	return *system_time;
}

void sif_systick(void)
{
	sif_task_systick();
	sif_task_reschedule();
}
