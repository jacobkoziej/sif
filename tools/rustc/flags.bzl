# SPDX-License-Identifier: MPL-2.0
#
# flags.bzl -- rustc constraint flags
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//tools/llvm/flags:arm.bzl",
    arm_profile="profile",
    arm_version="version",
)


def target() -> Select:
    def os() -> Select:
        return select(
            {
                "sif//constraints:os[linux]": "linux-gnu",
                "sif//constraints:os[macos]": "macos-gnu",
                "sif//constraints:os[sif]": "none",
                "DEFAULT": "none",
            }
        )

    def arm() -> Select:
        instruction_set = select(
            {
                "sif//constraints/arch/arm:profile[m]": "thumb",
                "DEFAULT": "arm",
            }
        )

        eabi = select(
            {
                "sif//constraints:eabihf[true]": "eabihf",
                "sif//constraints:eabihf[false]": "eabi",
            }
        )

        return instruction_set + arm_version() + arm_profile() + "-" + os() + "-" + eabi

    return select(
        {
            "sif//constraints:arch[aarch64]": "aarch64-unknown-" + os(),
            "sif//constraints:arch[arm]": arm(),
            "sif//constraints:arch[x86_64]": "x86_64-unknown-" + os(),
        }
    )
