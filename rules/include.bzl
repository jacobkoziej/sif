# SPDX-License-Identifier: MPL-2.0
#
# include.bzl -- include rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def _prefix_projection(prefix: str) -> typing.Callable[[Artifact], cmd_args]:
    def projection(path: Artifact | CellPath | cmd_args) -> cmd_args:
        return cmd_args(path, format=prefix + "{}")

    return projection


IncludeTSet = transitive_set(
    args_projections={
        prefix: _prefix_projection(prefix)
        for prefix in [
            "--library-path=",
            "-I",
            "-L",
        ]
    },
)

IncludeInfo = provider(
    fields={
        "paths": provider_field(TransitiveSet),
        "files": provider_field(list[Artifact]),
    },
)


Include = record(
    flags=TransitiveSetArgsProjection,
    files=cmd_args,
)


def get_include(
    actions: AnalysisActions,
    includes: list[IncludeInfo],
    prefix: str,
    ordering: str = "postorder",
) -> Include:
    return Include(
        flags=actions.tset(
            IncludeTSet,
            children=[include.paths for include in includes],
        ).project_as_args(prefix, ordering=ordering),
        files=cmd_args([include.files for include in includes]),
    )


def _include_impl(ctx: AnalysisContext) -> list[Provider]:
    return [
        DefaultInfo(),
        IncludeInfo(
            paths=ctx.actions.tset(IncludeTSet, value=ctx.label.path),
            files=ctx.attrs.files,
        ),
    ]


include = rule(
    impl=_include_impl,
    attrs={
        "files": attrs.list(attrs.source()),
    },
)
