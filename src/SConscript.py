# SPDX-License-Identifier: MPL-2.0
#
# SConscript.py
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

# ruff: noqa: F821

Import(
    [
        'arch',
        'env',
        'march',
    ]
)

arch = SConscript(
    f'arch/{arch}/SConscript.py',
    exports='env',
)

march = SConscript(
    f'march/{march}/SConscript.py',
    exports='env',
)

sif = env.StaticLibrary(
    target='sif',
    source=[
        arch,
        march,
        'list.c',
        'mutex.c',
        'sif.c',
        'syscall.c',
        'task.c',
    ],
)

Return('sif')
