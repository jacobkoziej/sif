/* SPDX-License-Identifier: MPL-2.0 */
/*
 * symbols.ld -- linker symbols
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

__bss_start__  = ADDR(.bss);
__bss_end__    = __bss_start__  + SIZEOF(.bss);

__data_load__  = LOADADDR(.data);
__data_start__ = ADDR(.data);
__data_end__   = __data_start__ + SIZEOF(.data);

__msp0_init__  = ORIGIN(SRAM4) + LENGTH(SRAM4);
__msp0_limit__ = ORIGIN(SRAM4);
__msp1_init__  = ORIGIN(SRAM5) + LENGTH(SRAM5);
__msp1_limit__ = ORIGIN(SRAM5);
