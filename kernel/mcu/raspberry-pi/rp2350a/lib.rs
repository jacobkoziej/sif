// SPDX-License-Identifier: MPL-2.0
//
// lib.rs -- rp2350a microcontroller
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

#![no_std]

const _: () = assert!(cfg!(target_arch = "arm"));
const _: () = assert!(cfg!(target_cpu = "cortex-m33"));
const _: () = assert!(cfg!(target_feature = "v8m.main"));
const _: () = assert!(cfg!(target_feature = "dsp"));
const _: () = assert!(cfg!(target_feature = "8msecext"));

use sif_arch::scs::scb::{VectorTable, default_handler};
use sif_core::McuInit;

#[derive(Default)]
pub struct Rp2350a;

pub type Mcu = Rp2350a;

impl McuInit for Rp2350a {
    fn init() {}
}

#[unsafe(no_mangle)]
#[unsafe(link_section = ".data.vector_table")]
pub(crate) static vector_table: VectorTable<52> = VectorTable {
    msp: 0,
    exceptions: [Some(default_handler); 15],
    interrupts: [Some(default_handler); 52],
};
