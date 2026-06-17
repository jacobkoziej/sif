# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- configuration rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Meta Platforms, Inc. and affiliates.
# <https://github.com/facebook/buck2-prelude/blob/8c031a1936f91633c0321e8c3c894e35c9066b9b/configurations/rules.bzl>


def _cfg_impl(ctx: AnalysisContext) -> list[Provider]:
    constraints = [
        constraint[ConstraintValueInfo] for constraint in ctx.attrs.constraints
    ]

    return [
        DefaultInfo(),
        ConfigurationInfo(
            constraints={
                constraint.setting.label: constraint for constraint in constraints
            },
            values={},
        ),
    ]


cfg = rule(
    impl=_cfg_impl,
    attrs={
        "constraints": attrs.list(
            attrs.dep(providers=[ConstraintValueInfo]),
            default=[],
        ),
    },
    is_configuration_rule=True,
)


def is_subset(a: ConfigurationInfo, b: ConfigurationInfo) -> bool:
    for a_constraint_value in a.constraints.values():
        setting_info = a_constraint_value.setting

        b_constraint_value = b.get(setting_info)

        if a_constraint_value != b_constraint_value:
            return False

    return True
