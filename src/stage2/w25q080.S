// SPDX-License-Identifier: MPL-2.0
/*
 * w25q080.S -- W25Q80 stage2 bootloader
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 *
 * Inspired by the original work of the Raspberry Pi Foundation
 * https://github.com/raspberrypi/pico-sdk/blob/2.0.0/src/rp2040/boot_stage2/boot2_w25q080.S
 */

	.syntax unified

	.arch armv6s-m
	.cpu  cortex-m0plus

#include "config.h"
#include "pads.h"
#include "ssi.h"
#include "w25q080.h"

#define PAD_CONFIG                              \
	( (PADS_DRIVE_8_MA << PADS_DRIVE_SHIFT) \
	| (1 << PADS_SLEWFAST_SHIFT) )

#define SSI_8_BIT_TX_RX_CONFIG                                      \
	( (SSI_CTRLR0_SPI_FRF_STANDARD << SSI_CTRLR0_SPI_FRF_SHIFT) \
	| ((8 - 1) << SSI_CTRLR0_DFS_32_SHIFT)                      \
	| (SSI_CTRLR0_TMOD_TX_RX << SSI_CTRLR0_TMOD_SHIFT) )

#define SSI_32_BIT_EEPROM_CONFIG                                    \
	( (SSI_CTRLR0_SPI_FRF_QUAD_SPI << SSI_CTRLR0_SPI_FRF_SHIFT) \
	| ((32 - 1) << SSI_CTRLR0_DFS_32_SHIFT)                     \
	| (SSI_CTRLR0_TMOD_EEPROM << SSI_CTRLR0_TMOD_SHIFT) )

#define WAIT_CYCLES    4
#define ADDRESS_LENGTH (32 / 4)

#define SSI_SPI_FRF_ADDRESS_FRAME_CONFIG                                             \
	( (WAIT_CYCLES << SSI_SPI_CTRLR0_WAIT_CYCLES_SHIFT)                          \
	| (SSI_SPI_CTRLR0_INST_L_8_BIT_INSTRUCTION << SSI_SPI_CTRLR0_INST_L_SHIFT)   \
	| (ADDRESS_LENGTH << SSI_SPI_CTRLR0_ADDR_L_SHIFT)                            \
	| (SSI_SPI_CTRLR0_TRANS_TYPE_FRF_ADDRESS << SSI_SPI_CTRLR0_TRANS_TYPE_SHIFT) )

#define SSI_SPI_XIP_CONFIG                                                                \
	( (W25Q80_FAST_READ_QUAD_IO_CONTINUOUS_READ_MODE << SSI_SPI_CTRLR0_XIP_CMD_SHIFT) \
	| (WAIT_CYCLES << SSI_SPI_CTRLR0_WAIT_CYCLES_SHIFT)                               \
	| (SSI_SPI_CTRLR0_INST_L_NO_INSTRUCTION << SSI_SPI_CTRLR0_INST_L_SHIFT)           \
	| (ADDRESS_LENGTH << SSI_SPI_CTRLR0_ADDR_L_SHIFT)                                 \
	| (SSI_SPI_CTRLR0_TRANS_TYPE_FRF << SSI_SPI_CTRLR0_TRANS_TYPE_SHIFT) )

	.text

	.section .text.stage2, "ax", %progbits

	.type   stage2, %function
	.global stage2
stage2:
	push {r4, r5, r6, r7, lr}

pad_config:
	ldr r4, =PADS_QSPI_BASE

	movs r0, #PAD_CONFIG
	str  r0, [r4, #PADS_QSPI_GPIO_QSPI_SCLK_OFFSET]

	ldr  r0, [r4, #PADS_QSPI_GPIO_QSPI_SD0_OFFSET]
	movs r1, #(1 << PADS_SCHMITT_SHIFT)
	bics r0, r1

	str r0, [r4, #PADS_QSPI_GPIO_QSPI_SD0_OFFSET]
	str r0, [r4, #PADS_QSPI_GPIO_QSPI_SD1_OFFSET]
	str r0, [r4, #PADS_QSPI_GPIO_QSPI_SD2_OFFSET]
	str r0, [r4, #PADS_QSPI_GPIO_QSPI_SD3_OFFSET]

clock_config:
	ldr r4, =SSI_BASE

	movs r6, #0
	str  r6, [r4, #SSI_SSIENR_OFFSET]

	movs r0, #CONFIG_FLASH_CLOCK_DIVISION 
	str  r0, [r4, #SSI_BAUDR_OFFSET]

	// add a 1-cycle sample delay in case
	// of data on the positive edge of SCLK
	movs r7, #1
	movs r0, #SSI_RX_SAMPLE_DLY_OFFSET
	str  r7, [r4, r0]

ssi_8_bit_tx_rx_config:
	ldr r0, =SSI_8_BIT_TX_RX_CONFIG
	str r0, [r4, #SSI_CTRLR0_OFFSET]

	str r7, [r4, #SSI_SSIENR_OFFSET]

check_quad_enable:
	mov  r0, r4
	movs r1, #W25Q80_READ_STATUS_REGISTER_2
	bl   read_status_register

	movs r1, #(1 << W25Q80_READ_STATUS_REGISTER_2_QE_SHIFT)
	cmp  r0, r1
	beq  skip_programming_quad_enable

program_quad_enable:
	movs r0, #W25Q80_WRITE_ENABLE
	str  r0, [r4, #SSI_DR0_OFFSET]

	mov r0, r4
	bl  flush_ssi_tx_fifo
	ldr r0, [r4, #SSI_DR0_OFFSET]

	movs r0, #W25Q80_WRITE_STATUS_REGISTER
	str  r0, [r4, #SSI_DR0_OFFSET]
	str  r6, [r4, #SSI_DR0_OFFSET]
	str  r6, [r4, #SSI_DR0_OFFSET]

	mov r0, r4
	bl  flush_ssi_tx_fifo
	ldr r0, [r4, #SSI_DR0_OFFSET]
	ldr r0, [r4, #SSI_DR0_OFFSET]
	ldr r0, [r4, #SSI_DR0_OFFSET]

.Lwait_for_write_complete:
	mov  r0, r4
	movs r1, #W25Q80_READ_STATUS_REGISTER_1
	bl   read_status_register
	movs r1, #(1 << W25Q80_READ_STATUS_REGISTER_1_BUSY_SHIFT)
	tst  r0, r1
	bne  .Lwait_for_write_complete

skip_programming_quad_enable:

ssi_32_bit_eeprom_config:
	str r6, [r4, #SSI_SSIENR_OFFSET]

	ldr r1, =SSI_32_BIT_EEPROM_CONFIG
	str r1, [r4, #SSI_CTRLR0_OFFSET]

set_number_of_data_frames:
	str r6, [r4, #SSI_CTRLR1_OFFSET]

ssi_spi_frf_address_frame_config:
	ldr r5, =SSI_SPI_CTRLR0_OFFSET
	ldr r0, =SSI_SPI_FRF_ADDRESS_FRAME_CONFIG
	str r0, [r4, r5]

	str r7, [r4, #SSI_SSIENR_OFFSET]

enable_continous_read_mode:
	movs r0, #W25Q80_FAST_READ_QUAD_IO
	str  r0, [r4, #SSI_DR0_OFFSET]
	movs r0, #W25Q80_FAST_READ_QUAD_IO_CONTINUOUS_READ_MODE 
	str  r0, [r4, #SSI_DR0_OFFSET]

	movs r0, r4
	bl   flush_ssi_tx_fifo

enable_xip:
	str r6, [r4, #SSI_SSIENR_OFFSET]

	ldr r0, =SSI_SPI_XIP_CONFIG
	str r0, [r4, r5]

	str r7, [r4, #SSI_SSIENR_OFFSET]

stage2_exit:
	pop {r4, r5, r6, r7, pc}
