// SPDX-License-Identifier: GPL-3.0-or-later
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
			// TODO: exit tickless idle

			core->running = core->queued;
			core->queued  = NULL;

			return core->running->stack.sp;
		}

		// TODO: tickless idle

		return sp;
	}

	// TODO: enter tickless idle
	if (!core->queued) return sp;

	return sif_task_context_switch(sp);
}

void sif_systick(void)
{
	sif_task_reschedule();
}
