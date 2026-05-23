// SPDX-License-Identifier: MPL-2.0
//
// lib.rs -- Arm architecture
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

#![no_std]

const _: () = assert!(cfg!(target_arch = "arm"));

use sif_core::ArchInit;

pub mod start;

pub struct Arm;

pub type Arch = Arm;

impl ArchInit for Arm {
    fn init() {}
}
