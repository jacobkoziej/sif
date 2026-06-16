// SPDX-License-Identifier: MPL-2.0
//
// elf.rs -- Executable and Linkable Format
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use core::mem::size_of;

/*
 * #cite(<tis-elf>)
 * 1.1-6 :: ELF Identification
 */
pub const EI_MAG0: usize = 0;
pub const EI_MAG1: usize = 1;
pub const EI_MAG2: usize = 2;
pub const EI_MAG3: usize = 3;
pub const EI_CLASS: usize = 4;
pub const EI_DATA: usize = 5;
pub const EI_VERSION: usize = 6;
pub const EI_PAD: usize = 7;
pub const EI_NIDENT: usize = 16;

// ei_ident[EI_MAG0..EI_MAG3]
pub const ELFMAG0: u8 = 0x7f;
pub const ELFMAG1: u8 = b'E';
pub const ELFMAG2: u8 = b'L';
pub const ELFMAG3: u8 = b'F';

// ei_ident[EI_CLASS]
pub const ELFCLASSNONE: u8 = 0;
pub const ELFCLASS32: u8 = 1;
pub const ELFCLASS64: u8 = 2;

// ei_ident[EI_DATA]
pub const ELFDATANONE: u8 = 0;
pub const ELFDATALSB: u8 = 1;
pub const ELFDATAMSB: u8 = 2;

/*
 * #cite(<tis-elf>)
 * 1.1-4 :: ELF Header
 */
#[repr(C)]
pub struct Header {
    pub e_ident: [u8; EI_NIDENT],
    pub e_type: u16,
    pub e_machine: u16,
    pub e_version: u32,
    pub e_entry: usize,
    pub e_phoff: usize,
    pub e_shoff: usize,
    pub e_flags: u32,
    pub e_ehsize: u16,
    pub e_phentsize: u16,
    pub e_phnum: u16,
    pub e_shentsize: u16,
    pub e_shnum: u16,
    pub e_shstrndx: u16,
}

#[cfg(target_pointer_width = "32")]
const _: () = assert!(size_of::<Header>() == 52);

#[cfg(target_pointer_width = "64")]
const _: () = assert!(size_of::<Header>() == 64);

/*
 * #cite(<tis-elf>)
 * 2.2-2 :: Program Header
 */
#[cfg(target_pointer_width = "32")]
#[repr(C)]
pub struct Phdr {
    pub p_type: u32,
    pub p_offset: usize,
    pub p_vaddr: usize,
    pub p_paddr: usize,
    pub p_filesz: u32,
    pub p_memsz: u32,
    pub p_flags: u32,
    pub p_align: u32,
}

#[cfg(target_pointer_width = "32")]
const _: () = assert!(size_of::<Phdr>() == 32);

#[cfg(target_pointer_width = "64")]
#[repr(C)]
pub struct Phdr {
    pub p_type: u32,
    pub p_flags: u32,
    pub p_offset: usize,
    pub p_vaddr: usize,
    pub p_paddr: usize,
    pub p_filesz: u64,
    pub p_memsz: u64,
    pub p_align: u64,
}

#[cfg(target_pointer_width = "64")]
const _: () = assert!(size_of::<Phdr>() == 56);

/*
 * #cite(<tis-elf>)
 * 1.1-10 :: Section Header
 */
#[cfg(target_pointer_width = "32")]
#[repr(C)]
pub struct Shdr {
    pub sh_name: u32,
    pub sh_type: u32,
    pub sh_flags: u32,
    pub sh_addr: usize,
    pub sh_off: usize,
    pub sh_size: u32,
    pub sh_link: u32,
    pub sh_info: u32,
    pub sh_addralign: u32,
    pub sh_entsize: u32,
}

#[cfg(target_pointer_width = "32")]
const _: () = assert!(size_of::<Shdr>() == 40);

#[cfg(target_pointer_width = "64")]
#[repr(C)]
pub struct Shdr {
    pub sh_name: u32,
    pub sh_type: u32,
    pub sh_flags: u64,
    pub sh_addr: usize,
    pub sh_off: usize,
    pub sh_size: u64,
    pub sh_link: u32,
    pub sh_info: u32,
    pub sh_addralign: u64,
    pub sh_entsize: u64,
}

#[cfg(target_pointer_width = "64")]
const _: () = assert!(size_of::<Shdr>() == 64);

/*
 * #cite(<tis-elf>)
 * 1.1-19 :: Symbol Table
 */
#[cfg(target_pointer_width = "32")]
#[repr(C)]
pub struct Sym {
    pub st_name: u32,
    pub st_value: usize,
    pub st_size: u32,
    pub st_info: u8,
    pub st_other: u8,
    pub st_shndx: u16,
}

#[cfg(target_pointer_width = "32")]
const _: () = assert!(size_of::<Sym>() == 16);

#[cfg(target_pointer_width = "64")]
#[repr(C)]
pub struct Sym {
    pub st_name: u32,
    pub st_info: u8,
    pub st_other: u8,
    pub st_shndx: u16,
    pub st_value: usize,
    pub st_size: u64,
}

#[cfg(target_pointer_width = "64")]
const _: () = assert!(size_of::<Sym>() == 24);
