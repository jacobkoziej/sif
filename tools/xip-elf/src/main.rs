// SPDX-License-Identifier: MPL-2.0
//
// main.rs -- xip-elf
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use clap::Parser;
use clap_num::maybe_hex;
use elf::ElfStream;
use elf::endian::{AnyEndian, EndianParse};
use elf::file::FileHeader;
use ihex::Record;
use std::convert::From;
use std::error::Error;
use std::fs::File;
use std::io;
use std::io::Write;
use std::mem::size_of;
use std::path::PathBuf;

/// generate ELF headers suitable for XIP
#[derive(Parser)]
#[command(about, version)]
struct Args {
    /// Path to input ELF
    input: PathBuf,

    /// Path to output Intel HEX
    #[arg(short, long)]
    output: Option<PathBuf>,

    /// Address to place ELF header (default: prepend to segment(s))
    #[arg(long, value_parser=maybe_hex::<u64>)]
    header_address: Option<u64>,

    /// Address to place ELF program header(s) (default: append to segment(s))
    #[arg(long, value_parser=maybe_hex::<u64>)]
    program_headers_address: Option<u64>,
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

fn bytes_to_ihex(address: u32, data: &[u8]) -> Vec<Record> {
    let mut records = Vec::<Record>::new();

    let mut address = address;

    for chunk in data.chunks(16 * 1024) {
        records.push(Record::ExtendedLinearAddress((address >> 16) as u16));

        let mut offset = (address & 0xFFFF) as u16;

        for bytes in chunk.chunks(16) {
            records.push(Record::Data {
                offset,
                value: bytes.to_vec(),
            });

            offset = offset.wrapping_add(16);
        }

        address = address.wrapping_add(16 * 1024);
    }

    records
}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();

    let mut p_types = vec![elf::abi::PT_LOAD];

    let file = ElfStream::<AnyEndian, _>::open_stream(File::open(&args.input)?)?;

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

    let header_address = match args.header_address {
        Some(address) => address,
        None => {
            let mut address = u64::MAX;

            for phdr in &phdrs {
                address = address.min(phdr.p_paddr);
            }

            address.wrapping_sub(match ehdr.class {
                elf::file::Class::ELF32 => size_of::<elf::file::Elf32_Ehdr>(),
                elf::file::Class::ELF64 => size_of::<elf::file::Elf64_Ehdr>(),
            } as u64)
        }
    };

    let program_headers_address = match args.program_headers_address {
        Some(address) => address,
        None => {
            let mut address = u64::MIN;

            for phdr in &phdrs {
                let end = phdr.p_paddr.wrapping_add(phdr.p_memsz);

                address = address.max(end);
            }

            address
        }
    };

    for phdr in &mut phdrs {
        phdr.p_offset = phdr.p_paddr.wrapping_sub(header_address);
    }

    ehdr.e_phoff = program_headers_address.wrapping_sub(header_address);
    ehdr.e_shoff = 0;
    ehdr.e_phnum = phdrs.len() as u16;
    ehdr.e_shnum = elf::abi::SHN_UNDEF;

    let header = Header(ehdr);
    let program_headers = phdrs.into_iter().map(|header| ProgramHeader {
        class: ehdr.class,
        endianness: ehdr.endianness,
        header,
    });

    let mut records = Vec::<Record>::new();

    if header_address > u32::MAX.into() {
        eprintln!(
            "warning: header address, 0x{:016x}, exceeds 32b address space.",
            header_address
        );
    }

    if program_headers_address > u32::MAX.into() {
        eprintln!(
            "warning: program header address, 0x{:016x}, exceeds 32b address space.",
            program_headers_address
        );
    }

    records.append(&mut bytes_to_ihex(
        header_address as u32,
        &Vec::from(header),
    ));
    records.append(&mut bytes_to_ihex(
        program_headers_address as u32,
        &program_headers
            .into_iter()
            .map(|header| Vec::from(header))
            .flatten()
            .collect::<Vec<u8>>(),
    ));
    records.push(Record::EndOfFile);

    let output = ihex::create_object_file_representation(&records).unwrap();

    let mut writer: Box<dyn Write> = match args.output {
        Some(path) => Box::new(File::create(path)?),
        None => Box::new(io::stdout()),
    };

    writer.write_all(output.as_bytes())?;

    Ok(())
}
