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

        return instruction_set + arm_version() + arm_profile() + "-none-" + eabi

    return select(
        {
            "sif//constraints:arch[arm]": arm(),
        }
    )
