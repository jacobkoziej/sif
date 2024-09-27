#!/usr/bin/env python3
# SPDX-License-Identifier: MPL-2.0
#
# stage2_crc32.py -- compute crc32 of stage2
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

import argparse
import binascii
import pathlib
import struct
import typing

CRC32_SEED: typing.Final[int] = 0
CRC32_SIZE: typing.Final[int] = 4

PAD_SIZE: typing.Final[int] = 256


def crc32(stage2: bytes) -> bytes:
    pad_size = PAD_SIZE - (CRC32_SIZE + len(stage2))

    assert pad_size >= 0

    stage2: bytes = stage2 + bytes([0xFF] * pad_size)

    checksum: int = rbit(
        (binascii.crc32(bytes(rbit(b, 8) for b in stage2), CRC32_SEED) ^ 0xFFFF_FFFF)
        & 0xFFFF_FFFF,
        32,
    )

    stage2 += struct.pack("<L", checksum)

    return stage2


def generate_assembly(stage2: bytes) -> str:
    asm: str = (
        "\t.syntax unified\n"
        + "\n"
        + "\t.arch armv6s-m\n"
        + "\t.cpu  cortex-m0plus\n"
        + "\n"
        + '\t.section .stage2, "ax", %progbits\n'
        + "\n"
    )

    for b in stage2:
        asm += f"\t.byte 0x{b:02x}\n"

    return asm


def main():
    parser: argparse.ArgumentParser = argparse.ArgumentParser()

    parser.add_argument(
        "-i",
        "--input",
        help="input file",
        metavar="stage2.bin",
        type=pathlib.Path,
    )
    parser.add_argument(
        "-o",
        "--output",
        help="output file",
        metavar="stage2.S",
        type=pathlib.Path,
    )

    args: argparse.Namespace = parser.parse_args()

    stage2: bytes = open(args.input, "rb").read()

    stage2: bytes = crc32(stage2)

    output: str = generate_assembly(stage2)

    with open(args.output, "w") as f:
        f.write(output)


def rbit(x: int, width: int) -> int:
    return int(f"{x:0{width}b}"[::-1], 2)


if __name__ == "__main__":
    main()
