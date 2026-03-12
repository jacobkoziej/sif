# SPDX-License-Identifier: MPL-2.0
#
# arm.bzl -- llvm arm constraint flags
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//utils:select.bzl", "nested_select")


def _bin_attr(constraint: str, flag: str) -> Select:
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


def _constraint(c: str) -> str:
    return "//constraints/arch/arm{}".format(c)


def features() -> Select:
    features = []

    for version in ["8", "8.1"]:
        for extension, flag in [
            ("cde", "cde"),
            ("dsp", "dsp"),
            ("security", "8msecext"),
        ]:
            features += _bin_attr(
                _constraint("/version/" + version + "/m/extension:" + extension),
                flag,
            )

    features += _bin_attr(_constraint("/version/8.1/m/extension:mve-i"), "mve")
    features += _bin_attr(_constraint("/version/8.1/m/extension:mve-f"), "mve.fp")
    features += _bin_attr(_constraint("/version/8.1/m/extension:pacbti"), "pacbti")
    features += _bin_attr(_constraint("/version/8.1/m/extension:pmu"), "perfmon")
    features += _bin_attr(_constraint("/version/8.1/m/extension:ras"), "ras")

    return features


def profile() -> Select:
    return select(
        {
            _constraint(":profile[m]"): select(
                {
                    _constraint(":version[8]"): select(
                        {
                            _constraint("/version/8/m/extension:main[true]"): "m.main",
                            _constraint("/version/8/m/extension:main[false]"): "m.base",
                        }
                    ),
                    _constraint(":version[8.1]"): select(
                        {
                            _constraint(
                                "/version/8.1/m/extension:main[true]"
                            ): "m.main",
                            _constraint(
                                "/version/8.1/m/extension:main[false]"
                            ): "m.base",
                        }
                    ),
                    "DEFAULT": "m",
                }
            ),
        }
    )


def version() -> Select:
    return select(
        {
            _constraint(":version[8]"): "v8",
        }
    )
