// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * macros.s -- armv6-m macros
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.macro SETUP_EXCEPTION_HANDLER vector_table, exception, handler
	mov r1, #(\exception * 4)
	add r1, r1, \vector_table
	ldr r0, =\handler
	str r0, [r1]
	.endm
