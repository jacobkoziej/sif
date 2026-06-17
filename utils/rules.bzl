# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- miscellaneous rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def _export_path_impl(ctx: AnalysisContext) -> list[Provider]:
    src = ctx.attrs.src
    dep = ctx.attrs.dep

    if (src == None) == (dep == None):
        fail("exactly one of `src` or `dep` must be set")

    out = src if src != None else dep[DefaultInfo].default_outputs[0]

    sub_targets = {
        path: [DefaultInfo(default_output=out.project(path))]
        for path in ctx.attrs.paths
    }

    return [
        DefaultInfo(
            default_output=out,
            sub_targets=sub_targets,
        )
    ]


_export_path = rule(
    impl=_export_path_impl,
    attrs={
        "src": attrs.option(attrs.source(allow_directory=True), default=None),
        "dep": attrs.option(attrs.exec_dep(), default=None),
        "paths": attrs.list(attrs.string(), default=[]),
    },
)


def export_path(
    path: str | None = None,
    *,
    sub_paths: list[str] = [],
    name: str | None = None,
    **kwargs: dict[str, typing.Any],
) -> None:
    _export_path(
        name=name or path,
        src=path,
        paths=sub_paths,
        **kwargs,
    )
