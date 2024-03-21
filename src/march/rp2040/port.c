// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port.c -- rp2040 port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <sif/arch/armv6-m/port-asm.h>
#include <sif/config.h>
#include <sif/march/rp2040/port-asm.h>
#include <sif/march/rp2040/port.h>

sif_task_stack_buffer_t *(* const sif_port_task_init_stack)(
    sif_task_stack_buffer_t *stack,
    sif_task_function_t	    *func,
    void		    *arg)
    = sif_arch_armv6_m_init_stack;
