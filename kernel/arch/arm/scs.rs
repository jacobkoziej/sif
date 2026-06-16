// SPDX-License-Identifier: MPL-2.0
//
// scs.rs -- System Control Space
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

// #cite(<armv8m-rm>)
// B8.2 :: The System region of the system address map

pub mod scb {
    pub const BASE: usize = 0xE000_ED00;

    #[cfg(target_feature = "8msecext")]
    pub const S_BASE: usize = BASE;

    #[cfg(target_feature = "8msecext")]
    pub const NS_BASE: usize = 0xE002_ED00;

    type Handler = unsafe extern "C" fn();

    pub unsafe extern "C" fn default_handler() {
        use core::arch::asm;

        loop {
            unsafe {
                asm!("bkpt", options(nomem, nostack));
            }
        }
    }

    #[repr(C)]
    pub struct VectorTable<const N: usize> {
        pub msp: usize,
        pub exceptions: [Option<Handler>; 15],
        pub interrupts: [Option<Handler>; N],
    }

    pub mod offset {
        pub const VTOR: usize = 0x8;
    }
}
