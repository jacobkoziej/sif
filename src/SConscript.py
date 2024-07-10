# SPDX-License-Identifier: MPL-2.0
#
# SConscript.py
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

# ruff: noqa: F821

Import('env')

rp2040 = env.StaticLibrary(
    target='rp2040',
    source=[
        'crt0.S',
        'vectors.S',
    ],
)

Return('rp2040')
