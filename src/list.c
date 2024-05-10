// SPDX-License-Identifier: MPL-2.0
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

void sif_list_bulk_append_back(
	sif_list_t ** const list, sif_list_t ** const back)
{
	if (!*back) return;

	if (!*list) {
		*list = *back;
		*back = NULL;
		return;
	}

	sif_list_t * const list_head = *list;
	sif_list_t * const list_tail = (*list)->prev;
	sif_list_t * const back_head = *back;
	sif_list_t * const back_tail = (*back)->prev;

	sif_list_insert(back_head, list_tail, back_head->next);
	sif_list_insert(back_tail, back_tail->prev, list_head);

	*back = NULL;
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

void sif_list_prepend_front(sif_list_t ** const list, sif_list_t * const node)
{
	sif_list_append_back(list, node);

	*list = node;
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

void sif_list_remove_next(sif_list_t ** const list, sif_list_t * const node)
{
	sif_list_t * const prev = node->prev;
	sif_list_t * const next = node->next;

	if ((node == prev) & (node == next)) {
		*list = NULL;
		return;
	}

	if (*list == node) *list = (*list)->next;

	sif_list_remove(node, prev, next);
}
