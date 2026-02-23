# SPDX-License-Identifier: MPL-2.0
#
# flags.bzl -- llvm constraint flags
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//utils:select.bzl", "nested_select")


def arch() -> Select:
    return select(
        {
            "//constraints:arch[aarch64]": "aarch64",
            "//constraints:arch[arm]": "arm",
            "//constraints:arch[x86_64]": "x86-64",
        }
    )


def attributes() -> Select:
    def bin_attr(constraint: str, flag: str) -> Select:
        base, _, version, profile, _ = constraint.rsplit("/", 4)

        return nested_select(
            [
                base + ":version[" + version + "]",
                base + ":profile[" + profile + "]",
            ],
            {
                constraint + "[true]": ["+" + flag],
                constraint + "[false]": ["-" + flag],
            },
            default=[],
        )

    def arm() -> Select:
        def constraint(c: str) -> str:
            return "//constraints/arch/arm{}".format(c)

        version = select(
            {
                constraint(":version[8]"): "v8",
            }
        )

        profile = select(
            {
                constraint(":profile[m]"): select(
                    {
                        constraint(":version[8]"): select(
                            {
                                constraint(
                                    "/version/8/m/extension:main[true]"
                                ): "m.main",
                                constraint(
                                    "/version/8/m/extension:main[false]"
                                ): "m.base",
                            }
                        ),
                        constraint(":version[8.1]"): select(
                            {
                                constraint(
                                    "/version/8.1/m/extension:main[true]"
                                ): "m.main",
                                constraint(
                                    "/version/8.1/m/extension:main[false]"
                                ): "m.base",
                            }
                        ),
                        "DEFAULT": "m",
                    }
                ),
            }
        )

        features = ["+" + version + profile]

        for version in ["8", "8.1"]:
            for extension, flag in [
                ("cde", "cde"),
                ("dsp", "dsp"),
                ("security", "8msecext"),
            ]:
                features += bin_attr(
                    constraint("/version/" + version + "/m/extension:" + extension),
                    flag,
                )

        features += bin_attr(constraint("/version/8.1/m/extension:mve-i"), "mve")
        features += bin_attr(constraint("/version/8.1/m/extension:mve-f"), "mve.fp")
        features += bin_attr(constraint("/version/8.1/m/extension:pacbti"), "pacbti")
        features += bin_attr(constraint("/version/8.1/m/extension:pmu"), "perfmon")
        features += bin_attr(constraint("/version/8.1/m/extension:ras"), "ras")

        return features

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
