# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- vendor rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//nix/rules.bzl",
    "derivation_copy",
    "get_system",
)
load("@sif//utils/rules.bzl", "export_path")


def src(
    *,
    name: str,
    sub_paths: list[str] = [],
    set_system: bool = True,
    **kwargs: dict[str, typing.Any],
) -> None:
    system = get_system() if set_system else None

    derivation_copy(
        name="_" + name,
        system=system,
        **kwargs,
    )

    export_path(
        name=name,
        dep=":_" + name,
        sub_paths=sub_paths,
    )
