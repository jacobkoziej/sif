# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- platform rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Meta Platforms, Inc. and affiliates.
# <https://github.com/facebook/buck2-prelude/blob/eb36d00d3ae63fb6baa76cafb3b07704e7fa0a53/configurations/rules.bzl>
# <https://github.com/facebook/buck2-prelude/blob/eb36d00d3ae63fb6baa76cafb3b07704e7fa0a53/configurations/util.bzl>


def _platform_impl(ctx: AnalysisContext) -> list[Provider]:
    configurations = [dep[PlatformInfo].configuration for dep in ctx.attrs.deps]

    constraints = [
        constraint[ConstraintValueInfo] for constraint in ctx.attrs.constraints
    ]
    configurations += [
        ConfigurationInfo(
            constraints={
                constraint.setting.label: constraint for constraint in constraints
            },
            values={},
        )
    ]

    constraints = {}
    values = {}

    for configuration in configurations:
        constraints.update(configuration.constraints)
        values.update(configuration.values)

    return [
        DefaultInfo(),
        PlatformInfo(
            label=str(ctx.label.raw_target()),
            configuration=ConfigurationInfo(
                constraints=constraints,
                values=values,
            ),
        ),
    ]


platform = rule(
    impl=_platform_impl,
    attrs={
        "constraints": attrs.list(
            attrs.dep(providers=[ConstraintValueInfo]),
            default=[],
        ),
        "deps": attrs.list(attrs.configuration_label(), default=[]),
    },
    is_configuration_rule=True,
)
