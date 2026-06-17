// SPDX-License-Identifier: MPL-2.0
//
// lib.rs -- sif core
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

#![no_std]

pub mod elf;

pub trait McuInit: Default {
    fn init();
}
