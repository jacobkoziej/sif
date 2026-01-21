# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- constraint rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Meta Platforms, Inc. and affiliates.
# <https://github.com/facebook/buck2-prelude/blob/8c031a1936f91633c0321e8c3c894e35c9066b9b/configurations/rules.bzl>


def _constraint_impl(ctx: AnalysisContext) -> list[Provider]:
    values = set(ctx.attrs.values)

    if len(values) != len(ctx.attrs.values):
        fail("constraint() values are not unique")

    reserved_values = ["default", "none"]

    for reserved_value in reserved_values:
        if reserved_value in values:
            fail("`{}` is a reserved constraint() value".format(reserved_value))

    values.add("none")

    default = ctx.attrs.default or "none"
    if default not in values:
        fail("default value `{}` must be a constraint() value".format(default))

    label = ctx.label.raw_target()
    constraint_setting = ConstraintSettingInfo(
        label=label,
        default=label.with_sub_target(default),
    )

    sub_targets = {}

    for value in values:
        constraint_value = ConstraintValueInfo(
            setting=constraint_setting,
            label=label.with_sub_target(value),
        )

        sub_targets[value] = [
            DefaultInfo(),
            constraint_value,
            ConfigurationInfo(
                constraints={
                    label: constraint_value,
                },
                values={},
            ),
        ]

    sub_targets["default"] = sub_targets[default]

    return [
        DefaultInfo(sub_targets=sub_targets),
        constraint_setting,
    ]


constraint = rule(
    impl=_constraint_impl,
    attrs={
        "values": attrs.list(attrs.string(), default=[]),
        "default": attrs.option(attrs.string(), default=None),
    },
    is_configuration_rule=True,
)
