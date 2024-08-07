// SPDX-License-Identifier: MPL-2.0
/*
 * port-asm.S -- armv6s-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6s-m

#include <sif/arch/armv6s-m/registers.h>

#define CONTEXT_OFFSET   0x20
#define EXCEPTION_OFFSET 0x20
#define LR_OFFSET        0x14
#define PC_OFFSET        0x18
#define R0_OFFSET        0x00
#define R1_OFFSET        0x04
#define XPSR_OFFSET      0x1c

	.macro RESTORE_CONTEXT sp
	ldm \sp!, {r4-r7}
	mov r8,   r4
	mov r9,   r5
	mov r10,  r6
	mov r11,  r7
	ldm \sp!, {r4-r7}
	msr psp,  \sp
	.endm

	.macro SAVE_CONTEXT sp
	mrs \sp, psp

	// save registers r4-r7
	sub   \sp,  \sp, #(CONTEXT_OFFSET - 16)
	stmia \sp!, {r4-r7}

	// save registers r8-r11
	mov r4,   r8
	mov r5,   r9
	mov r6,   r10
	mov r7,   r11
	sub \sp,  \sp, #CONTEXT_OFFSET
	stm \sp!, {r4-r7}

	// ensure \sp is at CONTEXT_OFFSET
	sub \sp, \sp, #(CONTEXT_OFFSET - 16)
	.endm

	.text

	.section .text.sif_arch_armv6s_m_handler_pendsv, "ax", %progbits

	.type   sif_arch_armv6s_m_handler_pendsv, %function
	.global sif_arch_armv6s_m_handler_pendsv
sif_arch_armv6s_m_handler_pendsv:
	push         {lr}
	SAVE_CONTEXT r0
	cpsid        i

	bl sif_pendsv

	cpsie           i
	RESTORE_CONTEXT r0
	dsb
	pop             {pc}

	.section .text.sif_arch_armv6s_m_handler_svcall, "ax", %progbits

	.type   sif_arch_armv6s_m_handler_svcall, %function
	.global sif_arch_armv6s_m_handler_svcall
sif_arch_armv6s_m_handler_svcall:
	push {r5,lr}

	// determine what sp to use for caller context
	ldr r5, =EXEC_RETURN_THREAD_MODE_PSP
	cmp r5, lr
	beq .Lpsp

	// ignore pushed registers on msp
	mov r5, sp
	add r5, r5, #8
	b   .Lextract_svc_immediate

.Lpsp:
	mrs r5, psp

.Lextract_svc_immediate:
	ldr  r1, [r5, #PC_OFFSET]
	sub  r1, r1,  #2
	ldrb r1, [r1]

	// check if svc immediate is zero
	tst r1, r1
	beq .Lvalid_svc_immediate

	// trigger a hard fault since we didn't execute svc
	svc #0

.Lvalid_svc_immediate:
	// extract syscall number
	ldr r0, [r5, #R0_OFFSET]

	// check if we have a valid syscall
	bl  sif_syscall_vaild
	tst r0, r0
	bne .Lset_syscall_return

	// get syscall
	ldr r0, [r5, #R0_OFFSET]
	ldr r1, =4
	mul r0, r0, r1
	ldr r1, =sif_syscalls
	add r1, r1, r0
	ldr r1, [r1]

	// call syscall with arg
	ldr r0, [r5, #R1_OFFSET]
	blx r1

	// check if we can reschedule
	push {r0}
	bl   sif_task_reschedule
	pop  {r0}

.Lset_syscall_return:
	str r0, [r5, #R0_OFFSET]

	pop {r5,pc}

	.section .text.sif_arch_armv6s_m_handler_systick, "ax", %progbits

	.type   sif_arch_armv6s_m_handler_systick, %function
	.global sif_arch_armv6s_m_handler_systick
sif_arch_armv6s_m_handler_systick:
	push {lr}
	bl   sif_systick
	pop  {pc}

	.section .text.sif_arch_armv6s_m_init, "ax", %progbits

	.type   sif_arch_armv6s_m_init, %function
	.global sif_arch_armv6s_m_init
sif_arch_armv6s_m_init:
	b sif_arch_armv6s_m_setup_nvic

	.section .text.sif_arch_armv6s_m_init_context, "ax", %progbits

	.type   sif_arch_armv6s_m_init_context, %function
	.global sif_arch_armv6s_m_init_context
sif_arch_armv6s_m_init_context:
	sub r0, r0, #EXCEPTION_OFFSET

	str r1, [r0, #PC_OFFSET]
	str r2, [r0, #R0_OFFSET]

	ldr r1, =sif_task_delete
	str r1, [r0, #LR_OFFSET]

	ldr r1, =(1 << EPSR_T)
	str r1, [r0, #XPSR_OFFSET]

	sub r0, r0, #CONTEXT_OFFSET

	bx lr

	.section .text.sif_arch_armv6s_m_interrupt_disable, "ax", %progbits

	.type   sif_arch_armv6s_m_interrupt_disable, %function
	.global sif_arch_armv6s_m_interrupt_disable
sif_arch_armv6s_m_interrupt_disable:
	cpsid i
	bx lr

	.section .text.sif_arch_armv6s_m_interrupt_enable, "ax", %progbits

	.type   sif_arch_armv6s_m_interrupt_enable, %function
	.global sif_arch_armv6s_m_interrupt_enable
sif_arch_armv6s_m_interrupt_enable:
	cpsie i
	bx lr

	.section .text.sif_arch_armv6s_m_pendsv_set, "ax", %progbits

	.type   sif_arch_armv6s_m_pendsv_set, %function
	.global sif_arch_armv6s_m_pendsv_set
sif_arch_armv6s_m_pendsv_set:
	ldr r0, =ICSR
	ldr r1, [r0]
	ldr r2, =(1 << ICSR_PENDSVSET)
	orr r1, r1, r2
	str r1, [r0]
	dsb
	isb
	bx  lr

	.section .text.sif_arch_armv6s_m_pendsv_clear, "ax", %progbits

	.type   sif_arch_armv6s_m_pendsv_clear, %function
	.global sif_arch_armv6s_m_pendsv_clear
sif_arch_armv6s_m_pendsv_clear:
	ldr r0, =ICSR
	ldr r1, [r0]
	ldr r2, =(1 << ICSR_PENDSVCLR)
	orr r1, r1, r2
	ldr r2, =~(1 << ICSR_PENDSVSET)
	and r1, r1, r2
	str r1, [r0]
	dsb
	isb
	bx  lr

	.section .text.sif_arch_armv6s_m_scheduler_start, "ax", %progbits

	.type   sif_arch_armv6s_m_scheduler_start, %function
	.global sif_arch_armv6s_m_scheduler_start
sif_arch_armv6s_m_scheduler_start:
	// reset msp
	ldr r1,  =VTOR
	ldr r1,  [r1]
	ldr r1,  [r1]
	msr msp, r1

	// pop context
	mov r1, r0
	add r1, r1,  #CONTEXT_OFFSET
	ldr r3, [r1, #LR_OFFSET]
	mov lr, r3
	ldr r3, [r1, #PC_OFFSET]
	ldr r2, [r1, #XPSR_OFFSET]
	ldr r0, [r1, #R0_OFFSET]
	add r1, r1,  #EXCEPTION_OFFSET

	// set special registers
	msr psp,        r1
	msr apsr_nzcvq, r2

	// switch to psp and jump to task
	ldr   r1,      =(1 << SPEL)
	msr   control, r1
	isb
	cpsie i
	bx    r3

	.section .text.sif_arch_armv6s_m_init, "ax", %progbits

	.type sif_arch_armv6s_m_setup_nvic, %function
sif_arch_armv6s_m_setup_nvic:
	push {lr}

	bl sif_arch_armv6s_m_setup_pendsv
	bl sif_arch_armv6s_m_setup_svcall
	bl sif_arch_armv6s_m_setup_systick

	// load vector table
	ldr r2, =VTOR
	ldr r2, [r2]

	// ensure SCS registers are updated (B2.5)
	dsb
	isb

	pop {pc}

	.section .text.sif_arch_armv6s_m_init, "ax", %progbits

	.type sif_arch_armv6s_m_setup_pendsv, %function
sif_arch_armv6s_m_setup_pendsv:
	// set pendsv to lowest priority
	ldr r1, =(0x03 << SHPR3_PRI_14)
	ldr r0, =SHPR3
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr

	.section .text.sif_arch_armv6s_m_init, "ax", %progbits

	.type sif_arch_armv6s_m_setup_svcall, %function
sif_arch_armv6s_m_setup_svcall:
	// set svcall priority
	ldr r1, =SIF_ARCH_ARMV6S_M_KERNEL_PRIORITY
	ldr r1, [r1]
	lsl r1, r1, #SHPR2_PRI_11
	ldr r0, =SHPR2
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr

	.section .text.sif_arch_armv6s_m_init, "ax", %progbits

	.type sif_arch_armv6s_m_setup_systick, %function
sif_arch_armv6s_m_setup_systick:
	// program our reload value
	ldr r0, =SYST_RVR
	ldr r1, =SIF_ARCH_ARMV6S_M_SYST_RVR_RELOAD
	ldr r1, [r1]
	str r1, [r0]

	// any write clears the current value
	ldr r0, =SYST_CVR
	str r1, [r0]

	// program control and status register
	ldr r0, =SYST_CSR
	ldr r1, =((1 << SYST_CSR_CLKSOURCE) | (1 << SYST_CSR_TICKINIT) | (1 << SYST_CSR_ENABLE))
	str r1, [r0]

	// set systick priority
	ldr r1, =SIF_ARCH_ARMV6S_M_KERNEL_PRIORITY
	ldr r1, [r1]
	lsl r1, r1, #SHPR3_PRI_15
	ldr r0, =SHPR3
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr

	.section .text.sif_arch_armv6s_m_syscall, "ax", %progbits

	.type   sif_arch_armv6s_m_syscall, %function
	.global sif_arch_armv6s_m_syscall
sif_arch_armv6s_m_syscall:
	svc #0
	bx  lr

	.section .text.sif_arch_armv6s_m_systick_count_flag, "ax", %progbits

	.type   sif_arch_armv6s_m_systick_count_flag, %function
	.global sif_arch_armv6s_m_systick_count_flag
sif_arch_armv6s_m_systick_count_flag:
	ldr r0, =SYST_CSR
	ldr r0, [r0]
	ldr r1, =(1 << SYST_CSR_COUNTFLAG)
	and r0, r0, r1
	bx  lr

	.section .text.sif_arch_armv6s_m_systick_current_value, "ax", %progbits

	.type   sif_arch_armv6s_m_systick_current_value, %function
	.global sif_arch_armv6s_m_systick_current_value
sif_arch_armv6s_m_systick_current_value:
	ldr r0, =SYST_CVR
	ldr r0, [r0]
	bx  lr

	.section .text.sif_arch_armv6s_m_wait_for_interrupt, "ax", %progbits

	.type   sif_arch_armv6s_m_wait_for_interrupt, %function
	.global sif_arch_armv6s_m_wait_for_interrupt
sif_arch_armv6s_m_wait_for_interrupt:
	wfi
	bx  lr
