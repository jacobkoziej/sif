# SPDX-License-Identifier: MPL-2.0
#
# flags.bzl -- rustc constraint flags
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "//tools/llvm/flags:arm.bzl",
    arm_profile="profile",
    arm_version="version",
)


def target() -> Select:
    def arm() -> Select:
        instruction_set = select(
            {
                "//constraints/arch/arm:profile[m]": "thumb",
                "DEFAULT": "arm",
            }
        )

        eabi = select(
            {
                "//constraints:eabihf[true]": "eabihf",
                "//constraints:eabihf[false]": "eabi",
            }
        )

        return instruction_set + arm_version() + arm_profile() + "-none-" + eabi

    return select(
        {
            "//constraints:arch[arm]": arm(),
        }
    )
