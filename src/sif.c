// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * sif.c -- a preemptive rtos
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/private/sif.h>
#include <sif/sif.h>

sif_t sif;

void sif_init(void)
{
	sif_port_init();
}

void sif_systick(void)
{
	sif_task_reschedule();
}
