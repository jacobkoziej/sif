# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- miscellaneous rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def _export_path_impl(ctx: AnalysisContext) -> list[Provider]:
    return [DefaultInfo(default_output=ctx.attrs.path)]


_export_path = rule(
    impl=_export_path_impl,
    attrs={
        "path": attrs.source(allow_directory=True),
    },
)


def export_path(
    path: str,
    *,
    name: str | None = None,
    visibility: list[str] | None,
) -> None:
    _export_path(
        name=name or path,
        path=path,
        visibility=visibility,
    )
