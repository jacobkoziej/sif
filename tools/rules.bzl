# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- tool rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//nix/rules.bzl", "derivation_output_path")


def _binary_path_impl(ctx: AnalysisContext) -> list[Provider]:
    path = ctx.attrs.path

    return [
        DefaultInfo(),
        RunInfo(
            args=cmd_args(path),
        ),
    ]


binary_path = rule(
    impl=_binary_path_impl,
    attrs={
        "path": attrs.string(),
    },
)


def binary(
    *,
    name: str,
    binary: str | None = None,
    set_system: bool = True,
    **kwargs: dict[str, typing.Any],
) -> None:
    path = read_config(package_name(), name, None)

    if path != None:
        binary_path(name=name, path=path)
        return

    system = (
        select(
            {
                "//constraints:os[linux]": select(
                    {
                        "//constraints:arch[x86_64]": "x86_64-linux",
                    }
                ),
            }
        )
        if set_system
        else None
    )

    derivation_output_path(
        name=name,
        path=["bin", binary or name],
        system=system,
        **kwargs,
    )
