// SPDX-License-Identifier: MPL-2.0
//
// start.rs -- early Arm initialization
// Copyright (C) 2026--2024  Jacob Koziej <jacobkoziej@gmail.com>

use core::arch::naked_asm;

#[unsafe(export_name = "_start_arch")]
#[unsafe(link_section = ".text._start")]
#[unsafe(naked)]
pub(crate) extern "C" fn start() {
    #[rustfmt::skip]
    naked_asm!(
r#"
    b _start
"#,
    );
}
