# SPDX-License-Identifier: MPL-2.0
#
# SConscript.py
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

# ruff: noqa: F821

Import('env')

mcu = [
    env.File(src)
    for src in [
        'port.c',
        'port-asm.s',
    ]
]

Return('mcu')
