// SPDX-License-Identifier: MPL-2.0
/*
 * list.h -- doubly linked list
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_LIST_H
#define SIF_LIST_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SIF_LIST_CONTAINER_OF(list, type, member) \
	((type *) (((uintptr_t) list) - offsetof(type, member)))

typedef struct sif_list {
	struct sif_list *prev;
	struct sif_list *next;
} sif_list_t;

void sif_list_append_back(sif_list_t ** const list, sif_list_t * const node);
void sif_list_bulk_append_back(
	sif_list_t ** const list, sif_list_t ** const back);
void sif_list_insert(sif_list_t * const node,
	sif_list_t * const		prev,
	sif_list_t * const		next);
void sif_list_node_init(sif_list_t * const node);
void sif_list_prepend_front(sif_list_t ** const list, sif_list_t * const node);
void sif_list_remove(sif_list_t * const node,
	sif_list_t * const		prev,
	sif_list_t * const		next);
void sif_list_remove_next(sif_list_t ** const list, sif_list_t * const node);

#endif	// SIF_LIST_H
