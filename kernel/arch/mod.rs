// SPDX-License-Identifier: MPL-2.0
//
// mod.rs -- abstract architecture module
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

#[cfg(target_arch = "arm")]
pub mod arm;

#[cfg(target_arch = "arm")]
pub use arm::*;
