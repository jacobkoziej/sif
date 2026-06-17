# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- tool rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//nix/rules.bzl",
    "derivation_output_path",
    "get_system",
)


def _tool_path_impl(ctx: AnalysisContext) -> list[Provider]:
    path = ctx.attrs.path

    return [
        DefaultInfo(),
        RunInfo(
            args=cmd_args(path),
        ),
    ]


tool_path = rule(
    impl=_tool_path_impl,
    attrs={
        "path": attrs.string(),
    },
)


def tool(
    *,
    name: str,
    binary: str | Select | None = None,
    set_system: bool = True,
    **kwargs: dict[str, typing.Any],
) -> None:
    path = read_config(package_name(), name, None)

    if path != None:
        tool_path(name=name, path=path)
        return

    system = get_system() if set_system else None

    derivation_output_path(
        name=name,
        path=["bin", binary or name],
        system=system,
        **kwargs,
    )
