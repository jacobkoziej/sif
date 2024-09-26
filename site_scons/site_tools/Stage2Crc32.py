# SPDX-License-Identifier: MPL-2.0
#
# Stage2Crc32.py -- compute crc32 of stage2
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

from SCons.Action import Action
from SCons.Builder import BuilderBase
from SCons.Script.SConscript import SConsEnvironment


def generate(env: SConsEnvironment) -> None:
    if env.Detect("Stage2Crc32"):
        return

    builder: BuilderBase = env.Builder(
        action=Action(
            "./site_scons/stage2_crc32.py --input $SOURCE --output $TARGET",
            "$STAGE2CRC32COMSTR",
        ),
    )

    env["BUILDERS"]["Stage2Crc32"] = builder


def exists(env: SConsEnvironment) -> bool:
    return env.Detect("Stage2Crc32")
