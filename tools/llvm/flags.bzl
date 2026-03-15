# SPDX-License-Identifier: MPL-2.0
#
# flags.bzl -- llvm constraint flags
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "//tools/llvm/flags:arm.bzl",
    arm_features="features",
    arm_profile="profile",
    arm_version="version",
)


def arch() -> Select:
    return select(
        {
            "//constraints:arch[aarch64]": "aarch64",
            "//constraints:arch[arm]": "arm",
            "//constraints:arch[x86_64]": "x86-64",
        }
    )


def attributes() -> Select:
    def arm() -> Select:
        features = ["+" + arm_version() + arm_profile()]

        return features + arm_features()

    return select(
        {
            "//constraints:arch[arm]": arm(),
            "DEFAULT": [],
        }
    )


def cpu() -> Select:
    return select(
        {
            "//constraints/arch/arm:cpu[cortex-m33]": "cortex-m33",
        }
    )


def opt_level() -> Select:
    return select(
        {
            "//constraints:opt-level[0]": "0",
            "//constraints:opt-level[1]": "1",
            "//constraints:opt-level[2]": "2",
            "//constraints:opt-level[3]": "3",
            "//constraints:opt-level[s]": "s",
            "//constraints:opt-level[z]": "z",
        }
    )
