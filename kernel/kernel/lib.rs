// SPDX-License-Identifier: MPL-2.0
//
// lib.rs -- sif
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

#![no_std]
#![no_main]

use core::panic::PanicInfo;
use sif_arch::Arch;
use sif_core::ArchInit;

#[unsafe(no_mangle)]
pub(crate) extern "C" fn main() {
    Arch::init();

    loop {}
}

#[panic_handler]
pub(crate) fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
