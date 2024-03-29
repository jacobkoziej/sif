// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * list.c -- doubly linked list
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/list.h>

void sif_list_init(sif_list_t * const list)
{
	list->prev = list;
	list->next = list;
}
