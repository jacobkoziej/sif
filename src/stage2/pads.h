// SPDX-License-Identifier: MPL-2.0
/*
 * pads.h -- rp2040 PADS
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#ifndef STAGE2_PADS
#define STAGE2_PADS

// 2.19.6
#define PADS_DRIVE_SHIFT    4
#define PADS_SCHMITT_SHIFT  1
#define PADS_SLEWFAST_SHIFT 0

#define PADS_DRIVE_8_MA 2

// 2.19.6.4
#define PADS_QSPI_BASE 0x40020000

#define PADS_QSPI_GPIO_QSPI_SCLK_OFFSET 0x04
#define PADS_QSPI_GPIO_QSPI_SD0_OFFSET  0x08
#define PADS_QSPI_GPIO_QSPI_SD1_OFFSET  0x0c
#define PADS_QSPI_GPIO_QSPI_SD2_OFFSET  0x10
#define PADS_QSPI_GPIO_QSPI_SD3_OFFSET  0x14

#endif // STAGE2_PADS
