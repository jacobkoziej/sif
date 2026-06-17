# SPDX-License-Identifier: MPL-2.0
#
# flags.bzl -- llvm constraint flags
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//tools/llvm/flags:arm.bzl",
    arm_features="features",
    arm_profile="profile",
    arm_version="version",
)


def arch() -> Select:
    return select(
        {
            "sif//constraints:arch[aarch64]": "aarch64",
            "sif//constraints:arch[arm]": "arm",
            "sif//constraints:arch[x86_64]": "x86-64",
        }
    )


def attributes() -> Select:
    def arm() -> Select:
        features = ["+" + arm_version() + arm_profile()]

        return features + arm_features()

    return select(
        {
            "sif//constraints:arch[arm]": arm(),
            "DEFAULT": [],
        }
    )


def cpu() -> Select:
    return select(
        {
            "sif//constraints/arch/arm:cpu[cortex-m33]": "cortex-m33",
        }
    )


def opt_level() -> Select:
    return select(
        {
            "sif//constraints:opt-level[0]": "0",
            "sif//constraints:opt-level[1]": "1",
            "sif//constraints:opt-level[2]": "2",
            "sif//constraints:opt-level[3]": "3",
            "sif//constraints:opt-level[s]": "s",
            "sif//constraints:opt-level[z]": "z",
        }
    )
