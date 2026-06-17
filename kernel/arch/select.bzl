# SPDX-License-Identifier: MPL-2.0
#
# select.bzl -- select architecture crate
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def select_arch() -> Select:
    return select(
        {
            "sif//constraints:arch[{}]".format(
                arch
            ): "sif//kernel/arch/{}:sif_arch".format(arch)
            for arch in [
                "arm",
            ]
        },
    )
