# SPDX-License-Identifier: MPL-2.0
#
# SConscript.py
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

# ruff: noqa: F821

Import("env")

link_flags = list(
    filter(
        lambda x: not x.startswith("-Wl,--script="),
        env["LINKFLAGS"],
    )
)

link_flags += ["-Wl,--script=stage2.ld"]

stage2_no_crc = env.Program(
    "stage2-no-crc",
    [
        "shared.S",
        f"{env['stage2']}.S",
    ],
    LIBS=[],
    LINKFLAGS=link_flags,
)

stage2_no_crc_bin = env.ObjCopy(
    "stage2-no-crc.bin",
    stage2_no_crc,
    OBJCOPYFLAGS="--output-target=binary",
)

stage2 = env.Stage2Crc32("stage2.S", stage2_no_crc_bin)

Return("stage2")
