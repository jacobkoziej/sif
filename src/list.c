// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * list.c -- doubly linked list
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/list.h>

#include <stddef.h>

void sif_list_append_back(sif_list_t ** const list, sif_list_t * const node)
{
	if (!*list) {
		*list = node;
		return;
	}

	sif_list_insert(node, (*list)->prev, *list);
}

void sif_list_insert(sif_list_t * const node,
	sif_list_t * const		prev,
	sif_list_t * const		next)
{
	node->prev = prev;
	node->next = next;

	prev->next = node;
	next->prev = node;
}

void sif_list_node_init(sif_list_t * const node)
{
	node->prev = node;
	node->next = node;
}

void sif_list_remove(sif_list_t * const node,
	sif_list_t * const		prev,
	sif_list_t * const		next)
{
	prev->next = next;
	next->prev = prev;

	node->prev = node;
	node->next = node;
}
