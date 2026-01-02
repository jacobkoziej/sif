# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- constraint rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Meta Platforms, Inc. and affiliates.
# <https://github.com/facebook/buck2-prelude/blob/eb36d00d3ae63fb6baa76cafb3b07704e7fa0a53/configurations/rules.bzl>


def _constraint_impl(ctx: AnalysisContext) -> list[Provider]:
    return [
        DefaultInfo(),
        ConstraintSettingInfo(
            label=ctx.label.raw_target(),
        ),
    ]


constraint = rule(
    impl=_constraint_impl,
    attrs={},
    is_configuration_rule=True,
)


def _constraint_value_impl(ctx: AnalysisContext) -> list[Provider]:
    return [
        DefaultInfo(),
        ConstraintValueInfo(
            setting=ctx.attrs.constraint[ConstraintSettingInfo],
            label=ctx.label.raw_target(),
        ),
    ]


constraint_value = rule(
    impl=_constraint_value_impl,
    attrs={
        "constraint": attrs.configuration_label(),
    },
    is_configuration_rule=True,
)
