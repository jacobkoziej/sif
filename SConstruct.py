# SPDX-License-Identifier: MPL-2.0
#
# SConstruct.py
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

# ruff: noqa: F821

import os
import sys

EnsureSConsVersion(4, 7, 0)
EnsurePythonVersion(3, 12)


AddOption(
    '--sif-src-dir',
    action='store',
    type='string',
    metavar='DIRECTORY',
    help='path to sif source directory',
)

if GetOption('help'):
    Return()


if not (sif_src_dir := GetOption('sif_src_dir')):
    sif_src_dir = os.environ.get('SIF_SRC_DIR', '')

if not os.path.isdir(sif_src_dir):
    print('sif source directory not found', file=sys.stderr)
    Exit(os.EX_OSFILE)


vars = Variables('overrides.py', ARGUMENTS)

vars.AddVariables(
    EnumVariable(
        'build_type',
        help='build type',
        default='release',
        allowed_values=('debug', 'release'),
    ),
    EnumVariable(
        'linker_script',
        help='linker script',
        default='no_flash',
        allowed_values=('no_flash',),
    ),
    BoolVariable(
        'verbose_output',
        help='enable verbose output',
        default=False,
    ),
)


arch = 'armv6s-m'
cpu = 'cortex-m0plus'
mcu = 'rp2040'


env = Environment(
    ENV={
        'PATH': os.environ['PATH'],
        'TERM': os.environ.get('TERM'),
    },
    LICENSE='MPL-2.0',
    variables=vars,
)
env.Replace(
    AR='arm-none-eabi-ar',
    AS='arm-none-eabi-gcc',
    CC='arm-none-eabi-gcc',
    CXX='arm-none-eabi-g++',
    LINK='arm-none-eabi-gcc',
    RANLIB='arm-none-eabi-gcc-ranlib',
    PROGSUFFIX='.elf',
)

common_flags = [
    '-Wall',
    '-Wextra',
    '-Wl,--library-path=ld',
    '-Wpedantic',
    '-fdata-sections',
    '-ffunction-sections',
    '-ggdb',
    '-nostartfiles',
    '-std=c2x',
    f'-Wl,--script=ld/{env['linker_script']}.ld',
    f'-march={arch}',
    f'-mcpu={cpu}',
]
includes = [
    f'{sif_src_dir}/include',
    f'{sif_src_dir}/include/sif/mcu/{mcu}/include',
]

if env['linker_script'] == 'no_flash':
    common_flags += ['-Wl,--no-warn-rwx-segments']

    env.AppendUnique(CPPDEFINES='NO_FLASH')

match env['build_type']:
    case 'debug':
        common_flags += [
            '-O0',
            '-ggdb',
        ]

    case 'release':
        common_flags += [
            '-O3',
            '-ffat-lto-objects',
            '-flto',
        ]

env.AppendUnique(
    ASFLAGS=common_flags,
    CCFLAGS=common_flags,
    CPPPATH=includes,
    LINKFLAGS=common_flags,
)

if not env['verbose_output']:
    env.AppendUnique(
        ARCOMSTR='ar $TARGET',
        ASCOMSTR='as $TARGET',
        ASPPCOMSTR='as $TARGET',
        CCCOMSTR='cc $TARGET',
        CXXCOMSTR='c++ $TARGET',
        LINKCOMSTR='ld $TARGET',
        RANLIBCOMSTR='ranlib $TARGET',
    )

build = f'build/{env['build_type']}'

rp2040 = SConscript(
    'src/SConscript.py',
    exports=[
        'env',
    ],
    variant_dir=f'{build}/src',
)

sif = SConscript(
    f'{sif_src_dir}/src/SConscript.py',
    exports=[
        'arch',
        'env',
        'mcu',
    ],
    variant_dir=f'{build}/lib/sif/src',
)

env.AppendUnique(
    LIBS=[
        rp2040,
        sif,
    ],
)
