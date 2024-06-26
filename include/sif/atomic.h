// SPDX-License-Identifier: MPL-2.0
/*
 * atmoic.h -- atomics
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ATOMIC_H
#define SIF_ATOMIC_H

#include <sif/port.h>

typedef sif_port_atomic_t sif_atomic_t;

extern sif_atomic_t (* const sif_port_atomic_test_and_set)(sif_atomic_t *var);

#endif	// SIF_ATMOIC_H
