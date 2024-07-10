// SPDX-License-Identifier: MPL-2.0
/*
 * types.h -- armv6s-m types
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef SIF_ARCH_ARMV6S_M_TYPES_H
#define SIF_ARCH_ARMV6S_M_TYPES_H

typedef void sif_arch_armv6s_m_exception_handler_t(void);

typedef unsigned long			   sif_arch_armv6s_m_word_t;
typedef volatile sif_arch_armv6s_m_word_t *sif_arch_armv6s_m_register_t;

#endif	// SIF_ARCH_ARMV6S_M_TYPES_H
