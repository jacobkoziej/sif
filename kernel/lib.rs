// SPDX-License-Identifier: MPL-2.0
//
// lib.rs -- sif
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

#![no_std]
#![no_main]

pub mod arch;

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub(crate) extern "C" fn main() {
    loop {}
}

#[panic_handler]
pub(crate) fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
