# SPDX-License-Identifier: MPL-2.0
#
# select.bzl -- select MCU crate
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def select_mcu() -> Select:
    return select(
        {
            "sif//constraints:vendor[{}]".format(vendor): select(
                {
                    "sif//constraints/vendor/{vendor}:mcu[{mcu}]".format(
                        vendor=vendor, mcu=mcu
                    ): "sif//kernel/mcu/{vendor}/{mcu}:sif_mcu".format(
                        vendor=vendor, mcu=mcu
                    )
                    for mcu in mcus
                },
            )
            for vendor, mcus in {
                "raspberry-pi": [
                    "rp2350a",
                ],
            }.items()
        },
    )
