// SPDX-License-Identifier: MPL-2.0
//
// lib.rs -- sif core
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

#![cfg_attr(not(test), no_std)]
#![feature(allocator_ext)]
#![feature(const_atomic)]
#![feature(ptr_metadata)]

pub mod elf;
pub mod list;

pub trait McuInit: Default {
    fn init();
}
