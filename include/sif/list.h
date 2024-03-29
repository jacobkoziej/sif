// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * list.h -- doubly linked list
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_LIST_H
#define SIF_LIST_H

#include <stddef.h>
#include <stdint.h>

#define SIF_LIST_CONTAINER_OF(list, type, member) \
	((type *) (((uintptr_t) list) - offsetof(type, member)))

typedef struct sif_list {
	struct sif_list *prev;
	struct sif_list *next;
} sif_list_t;

void sif_list_init(sif_list_t * const list);
void sif_list_insert(sif_list_t * const list, sif_list_t * const node);

#endif	// SIF_LIST_H
