# SPDX-License-Identifier: MPL-2.0
#
# include.bzl -- include rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def _prefix_projection(prefix: str) -> typing.Callable[[Artifact], cmd_args]:
    def projection(path: Artifact) -> cmd_args:
        return cmd_args(path.short_path, format=prefix + "{}")

    return projection


IncludeTSet = transitive_set(
    args_projections={
        prefix: _prefix_projection(prefix)
        for prefix in [
            "-I",
        ]
    },
)

IncludeInfo = provider(
    fields={
        "paths": provider_field(TransitiveSet),
    },
)


def _include_impl(ctx: AnalysisContext) -> list[Provider]:
    children = [ctx.actions.tset(IncludeTSet, value=path) for path in ctx.attrs.paths]

    return [
        DefaultInfo(),
        IncludeInfo(
            paths=ctx.actions.tset(IncludeTSet, children=children),
        ),
    ]


include = rule(
    impl=_include_impl,
    attrs={
        "paths": attrs.list(attrs.source(allow_directory=True)),
    },
)
