/* SPDX-License-Identifier: MPL-2.0 */
/*
 * symbols.ld -- generic symbols
 * Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
 */

PROVIDE(__rodata_ehdr__ = LOADADDR(.rodata.ehdr));

PROVIDE(__swapper_stack_start__ = ADDR(.bss.swapper_stack));
PROVIDE(__swapper_stack_end__ = __swapper_stack_start__ + SIZEOF(.bss.swapper_stack));
