// SPDX-License-Identifier: MPL-2.0
/*
 * mutex.c -- test mutex
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/mutex.h>
#include <sif/sif.h>
#include <sif/task.h>

#include <stdlib.h>

#define COUNT 1000
#define TASKS 10

static sif_task_stack_t stack[TASKS + 2][SIF_CONFIG_MINIMUM_STACK_SIZE];
static sif_task_t	tasks[TASKS + 2];

static sif_mutex_t mutex;
static sif_word_t  counter;

static sif_mutex_t priority_boost;

void task(void *arg)
{
	(void) arg;

	for (sif_word_t i = 0; i < COUNT; i++) {
		sif_mutex_lock(&mutex);
		++counter;
		sif_mutex_unlock(&mutex);
	}
}

void low_priority(void *arg)
{
	(void) arg;
loop:

	sif_mutex_lock(&priority_boost);

	for (unsigned i = 0; i < 1000000; i++) continue;

	sif_mutex_unlock(&priority_boost);

	goto loop;
}

void high_priority(void *arg)
{
	(void) arg;
loop:

	sif_task_tick_delay(10);

	sif_mutex_lock(&priority_boost);

	sif_task_tick_delay(1);

	sif_mutex_unlock(&priority_boost);

	goto loop;
}

int main(void)
{
	sif_init();

	sif_mutex_init(&mutex);

	for (size_t i = 0; i < TASKS; i++) {
		sif_task_init(&tasks[i],
			&(sif_task_config_t){
				.func	    = task,
				.arg	    = NULL,
				.priority   = 2,
				.cpu_mask   = (1 << 0),
				.stack	    = stack[i],
				.stack_size = sizeof(stack[i]),
			});
		sif_task_add(&tasks[i]);
	}

	sif_task_init(&tasks[TASKS + 1 - 1],
		&(sif_task_config_t){
			.func	    = high_priority,
			.arg	    = NULL,
			.priority   = 0,
			.cpu_mask   = (1 << 0),
			.stack	    = stack[TASKS + 1 - 1],
			.stack_size = sizeof(stack[TASKS + 1 - 1]),
		});
	sif_task_add(&tasks[TASKS + 1 - 1]);

	sif_task_init(&tasks[TASKS + 2 - 1],
		&(sif_task_config_t){
			.func	    = low_priority,
			.arg	    = NULL,
			.priority   = 1,
			.cpu_mask   = (1 << 0),
			.stack	    = stack[TASKS + 2 - 1],
			.stack_size = sizeof(stack[TASKS + 1 - 1]),
		});
	sif_task_add(&tasks[TASKS + 2 - 1]);

	sif_task_scheduler_start();

	return EXIT_SUCCESS;
}
