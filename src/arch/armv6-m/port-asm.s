// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * port-asm.s -- armv6-m port
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

	.arch armv6s-m

	.include "sif/arch/armv6-m/macros.s"
	.include "sif/arch/armv6-m/registers.s"

	.text

	.type   sif_arch_armv6_m_init, %function
	.global sif_arch_armv6_m_init
sif_arch_armv6_m_init:
	push {lr}
	bl   sif_arch_armv6_m_setup_nvic
	pop  {pc}

	.type   sif_arch_armv6_m_init_context, %function
	.global sif_arch_armv6_m_init_context
sif_arch_armv6_m_init_context:
	sub r0, r0, #EXCEPTION_OFFSET

	str r1, [r0, #PC_OFFSET]
	str r2, [r0, #R0_OFFSET]

	ldr r1, =sif_task_delete
	str r1, [r0, #LR_OFFSET]

	ldr r1, =(1 << EPSR_T)
	str r1, [r0, #XPSR_OFFSET]

	sub r0, r0, #CONTEXT_OFFSET

	bx lr

	.type   sif_arch_armv6_m_interrupt_disable, %function
	.global sif_arch_armv6_m_interrupt_disable
sif_arch_armv6_m_interrupt_disable:
	cpsid i
	bx lr

	.type   sif_arch_armv6_m_interrupt_enable, %function
	.global sif_arch_armv6_m_interrupt_enable
sif_arch_armv6_m_interrupt_enable:
	cpsie i
	bx lr

	.type sif_arch_armv6_m_handler_pendsv, %function
sif_arch_armv6_m_handler_pendsv:
	push         {lr}
	SAVE_CONTEXT r0

	bkpt

	RESTORE_CONTEXT r0
	pop             {pc}

	.type sif_arch_armv6_m_handler_svcall, %function
sif_arch_armv6_m_handler_svcall:
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

.Lset_syscall_return:
	str r0, [r5, #R0_OFFSET]

	pop {r5,pc}

	.type sif_arch_armv6_m_handler_systick, %function
sif_arch_armv6_m_handler_systick:
	push {lr}
	bl   sif_systick
	pop  {pc}

	.type   sif_arch_armv6_m_pendsv_set, %function
	.global sif_arch_armv6_m_pendsv_set
sif_arch_armv6_m_pendsv_set:
	ldr r0, =ICSR
	ldr r1, [r0]
	ldr r2, =(1 << ICSR_PENDSVSET)
	orr r1, r1, r2
	str r1, [r0]
	dsb
	isb
	bx  lr

	.type   sif_arch_armv6_m_pendsv_clear, %function
	.global sif_arch_armv6_m_pendsv_clear
sif_arch_armv6_m_pendsv_clear:
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

	.type   sif_arch_armv6_m_scheduler_start, %function
	.global sif_arch_armv6_m_scheduler_start
sif_arch_armv6_m_scheduler_start:
	// reset msp
	ldr r1,  =VTOR
	ldr r1,  [r1]
	ldr r1,  [r1]
	msr msp, r1

	// pop context
	mov r1, r0
	add r1, r1,  #CONTEXT_OFFSET
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

	.type sif_arch_armv6_m_setup_nvic, %function
sif_arch_armv6_m_setup_nvic:
	push {lr}

	bl sif_arch_armv6_m_setup_pendsv
	bl sif_arch_armv6_m_setup_svcall
	bl sif_arch_armv6_m_setup_systick

	// load vector table
	ldr r2, =VTOR
	ldr r2, [r2]

	SETUP_EXCEPTION_HANDLER r2, EXCEPTION_NUMBER_PENDSV,  sif_arch_armv6_m_handler_pendsv
	SETUP_EXCEPTION_HANDLER r2, EXCEPTION_NUMBER_SVCALL,  sif_arch_armv6_m_handler_svcall
	SETUP_EXCEPTION_HANDLER r2, EXCEPTION_NUMBER_SYSTICK, sif_arch_armv6_m_handler_systick

	// ensure SCS registers are updated (B2.5)
	dsb
	isb

	pop {pc}

	.type sif_arch_armv6_m_setup_pendsv, %function
sif_arch_armv6_m_setup_pendsv:
	// set pendsv to lowest priority
	ldr r1, =(0x03 << SHPR3_PRI_14)
	ldr r0, =SHPR3
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr

	.type sif_arch_armv6_m_setup_svcall, %function
sif_arch_armv6_m_setup_svcall:
	// set svcall priority
	ldr r1, =SIF_ARCH_ARMV6_M_KERNEL_PRIORITY
	ldr r1, [r1]
	lsl r1, r1, #SHPR2_PRI_11
	ldr r0, =SHPR2
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr

	.type sif_arch_armv6_m_setup_systick, %function
sif_arch_armv6_m_setup_systick:
	// program our reload value
	ldr r0, =SYST_RVR
	ldr r1, =SIF_ARCH_ARMV6_M_SYST_RVR_RELOAD
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
	ldr r1, =SIF_ARCH_ARMV6_M_KERNEL_PRIORITY
	ldr r1, [r1]
	lsl r1, r1, #SHPR3_PRI_15
	ldr r0, =SHPR3
	ldr r2, [r0]
	orr r1, r1, r2
	str r1, [r0]

	bx lr

	.type   sif_arch_armv6_m_syscall, %function
	.global sif_arch_armv6_m_syscall
sif_arch_armv6_m_syscall:
	svc #0
	bx  lr
