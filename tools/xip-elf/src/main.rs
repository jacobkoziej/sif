// SPDX-License-Identifier: MPL-2.0
//
// main.rs -- xip-elf
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use clap::Parser;
use elf::ElfStream;
use elf::endian::{AnyEndian, EndianParse};
use elf::file::FileHeader;
use std::convert::From;
use std::error::Error;
use std::fs::{File, OpenOptions, copy};
use std::io::{Seek, SeekFrom, Write};
use std::mem::size_of;
use std::path::PathBuf;

/// generate ELF headers suitable for XIP
#[derive(Parser)]
#[command(about, version)]
struct Args {
    /// Path to ELF
    elf: PathBuf,

    /// Section to place ELF header
    #[arg(long, default_value = ".rodata.ehdr")]
    ehdr: String,

    /// Section to place program header(s)
    #[arg(long, default_value = ".rodata.phdrs")]
    phdrs: String,

    /// Path to output modified ELF instead of operating in-place
    #[arg(short, long)]
    output: Option<PathBuf>,
}

struct Header<E: EndianParse>(FileHeader<E>);

impl<E: EndianParse> From<Header<E>> for Vec<u8> {
    fn from(header: Header<E>) -> Self {
        let header = header.0;

        let mut buf = Vec::<u8>::with_capacity(size_of::<elf::file::Elf64_Ehdr>());

        use elf::file::Class::*;

        // e_ident
        buf.extend_from_slice(&[0x7F, b'E', b'L', b'F']);
        buf.push(match header.class {
            ELF32 => 1,
            ELF64 => 2,
        });
        buf.push(if header.endianness.is_little() { 1 } else { 2 });
        buf.push(header.version as u8);
        buf.resize(buf.len() + 9, 0);

        let u16_bytes: fn(u16) -> [u8; 2];
        let u32_bytes: fn(u32) -> [u8; 4];
        let u64_bytes: fn(u64) -> [u8; 8];

        if header.endianness.is_little() {
            u16_bytes = u16::to_le_bytes;
            u32_bytes = u32::to_le_bytes;
            u64_bytes = u64::to_le_bytes;
        } else {
            u16_bytes = u16::to_be_bytes;
            u32_bytes = u32::to_be_bytes;
            u64_bytes = u64::to_be_bytes;
        }

        buf.extend_from_slice(&u16_bytes(header.e_type));
        buf.extend_from_slice(&u16_bytes(header.e_machine));
        buf.extend_from_slice(&u32_bytes(header.version));

        match header.class {
            ELF32 => {
                buf.extend_from_slice(&u32_bytes(header.e_entry as u32));
                buf.extend_from_slice(&u32_bytes(header.e_phoff as u32));
                buf.extend_from_slice(&u32_bytes(header.e_shoff as u32));
            }
            ELF64 => {
                buf.extend_from_slice(&u64_bytes(header.e_entry));
                buf.extend_from_slice(&u64_bytes(header.e_phoff));
                buf.extend_from_slice(&u64_bytes(header.e_shoff));
            }
        }

        buf.extend_from_slice(&u32_bytes(header.e_flags));
        buf.extend_from_slice(&u16_bytes(header.e_ehsize));
        buf.extend_from_slice(&u16_bytes(header.e_phentsize));
        buf.extend_from_slice(&u16_bytes(header.e_phnum));
        buf.extend_from_slice(&u16_bytes(header.e_shentsize));
        buf.extend_from_slice(&u16_bytes(header.e_shnum));
        buf.extend_from_slice(&u16_bytes(header.e_shstrndx));

        buf
    }
}

struct ProgramHeader<E: EndianParse> {
    class: elf::file::Class,
    endianness: E,
    header: elf::segment::ProgramHeader,
}

impl<E: EndianParse> From<ProgramHeader<E>> for Vec<u8> {
    fn from(header: ProgramHeader<E>) -> Self {
        let u32_bytes: fn(u32) -> [u8; 4];
        let u64_bytes: fn(u64) -> [u8; 8];

        if header.endianness.is_little() {
            u32_bytes = u32::to_le_bytes;
            u64_bytes = u64::to_le_bytes;
        } else {
            u32_bytes = u32::to_be_bytes;
            u64_bytes = u64::to_be_bytes;
        }

        let class = header.class;
        let header = header.header;

        let mut buf = Vec::<u8>::with_capacity(size_of::<elf::segment::Elf64_Phdr>());

        buf.extend_from_slice(&u32_bytes(header.p_type));

        match class {
            elf::file::Class::ELF32 => {
                buf.extend_from_slice(&u32_bytes(header.p_offset as u32));
                buf.extend_from_slice(&u32_bytes(header.p_vaddr as u32));
                buf.extend_from_slice(&u32_bytes(header.p_paddr as u32));
                buf.extend_from_slice(&u32_bytes(header.p_filesz as u32));
                buf.extend_from_slice(&u32_bytes(header.p_memsz as u32));
                buf.extend_from_slice(&u32_bytes(header.p_flags));
                buf.extend_from_slice(&u32_bytes(header.p_align as u32));
            }
            elf::file::Class::ELF64 => {
                buf.extend_from_slice(&u32_bytes(header.p_flags));
                buf.extend_from_slice(&u64_bytes(header.p_offset));
                buf.extend_from_slice(&u64_bytes(header.p_vaddr));
                buf.extend_from_slice(&u64_bytes(header.p_paddr));
                buf.extend_from_slice(&u64_bytes(header.p_filesz));
                buf.extend_from_slice(&u64_bytes(header.p_memsz));
                buf.extend_from_slice(&u64_bytes(header.p_align));
            }
        }

        buf
    }
}

fn vma2lma(phdrs: &[elf::segment::ProgramHeader], addr: u64) -> Option<u64> {
    for phdr in phdrs {
        let p_vaddr = phdr.p_vaddr;
        let p_memsz = phdr.p_memsz;

        if (addr >= p_vaddr) && (addr < p_vaddr + p_memsz) {
            let offset = addr - p_vaddr;

            return Some(phdr.p_paddr + offset);
        }
    }

    None
}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();

    let mut p_types = vec![elf::abi::PT_LOAD];

    let mut file = ElfStream::<AnyEndian, _>::open_stream(File::open(&args.elf)?)?;

    let mut ehdr = file.ehdr;

    {
        use elf::abi::*;

        match ehdr.e_machine {
            EM_ARM => {
                p_types.push(PT_ARM_UNWIND);
            }
            e_machine => return Err(format!("unknown e_machine: 0x{:x}", e_machine).into()),
        }
    }

    let mut phdrs: Vec<_> = file
        .segments()
        .iter()
        .filter(|s| p_types.contains(&s.p_type))
        .copied()
        .collect();

    let ehdr_shdr = *file.section_header_by_name(&args.ehdr)?.ok_or(format!(
        "ELF header output section `{}` not found",
        args.ehdr
    ))?;

    let Some(ehdr_addr) = vma2lma(&phdrs, ehdr_shdr.sh_addr) else {
        return Err(format!("ELF header output section must be allocatable").into());
    };

    if ehdr_addr != ehdr_shdr.sh_addr {
        return Err(format!("ELF header output section must be XIP").into());
    }

    let phdrs_shdr = *file.section_header_by_name(&args.phdrs)?.ok_or(format!(
        "Program header(s) output section `{}` not found",
        args.phdrs
    ))?;

    let Some(phdrs_addr) = vma2lma(&phdrs, phdrs_shdr.sh_addr) else {
        return Err(format!("Program header(s) output section must be allocatable").into());
    };

    if phdrs_addr != phdrs_shdr.sh_addr {
        return Err(format!("Program header(s) output section must be XIP").into());
    }

    for phdr in &mut phdrs {
        phdr.p_offset = phdr.p_paddr.wrapping_sub(ehdr_addr);
    }

    ehdr.e_phoff = phdrs_addr.wrapping_sub(phdrs_addr);
    ehdr.e_shoff = 0;
    ehdr.e_phnum = phdrs.len() as u16;
    ehdr.e_shnum = elf::abi::SHN_UNDEF;

    let header = Vec::from(Header(ehdr));

    if header.len() > ehdr_shdr.sh_size as usize {
        return Err(format!("ELF header cannot fit in output section").into());
    }

    let program_headers: Vec<_> = phdrs
        .into_iter()
        .map(|header| {
            Vec::from(ProgramHeader {
                class: ehdr.class,
                endianness: ehdr.endianness,
                header,
            })
        })
        .flatten()
        .collect();

    if program_headers.len() > phdrs_shdr.sh_size as usize {
        return Err(format!("Program header(s) cannot fit in output section").into());
    }

    let path = match args.output {
        Some(path) => {
            copy(&args.elf, &path)?;

            path
        }
        None => args.elf,
    };

    let mut file = OpenOptions::new().write(true).open(path)?;

    file.seek(SeekFrom::Start(ehdr_shdr.sh_offset))?;
    file.write_all(&header)?;

    file.seek(SeekFrom::Start(phdrs_shdr.sh_offset))?;
    file.write_all(&program_headers)?;

    Ok(())
}
