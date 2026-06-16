# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- constraint rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Meta Platforms, Inc. and affiliates.
# <https://github.com/facebook/buck2-prelude/blob/8c031a1936f91633c0321e8c3c894e35c9066b9b/configurations/rules.bzl>

load("@sif//utils:dict.bzl", "obj_to_dict")

ConstraintValues = dict[str, list[Provider]]

_constraint_attrs: dict[str, Attr] = {
    "values": attrs.list(attrs.string(), default=[]),
    "nullable": attrs.bool(default=True),
    "default": attrs.option(attrs.string(), default=None),
}


def construct_constraint(
    label: TargetLabel | str,
    values: list[str],
    default: str | None,
    nullable: bool,
) -> (ConstraintSettingInfo, ConstraintValues):
    if len(set(values)) != len(values):
        fail("constraint values are not unique")

    reserved_values = ["default", "none"]

    for reserved_value in reserved_values:
        if reserved_value in values:
            fail("`{}` is a reserved constraint value".format(reserved_value))

    if nullable:
        values.append("none")

    elif default == None:
        fail("default value must be specified for non-nullable constraint value")

    default = default or "none"
    if default not in values:
        fail("default value `{}` must be a constraint value".format(default))

    constraint_setting = ConstraintSettingInfo(
        label=label,
        default=label.with_sub_target(default),
    )

    constraint_values = {}

    for value in values:
        constraint_value = ConstraintValueInfo(
            setting=constraint_setting,
            label=label.with_sub_target(value),
        )

        constraint_values[value] = [
            DefaultInfo(),
            constraint_value,
            ConfigurationInfo(
                constraints={
                    label: constraint_value,
                },
                values={},
            ),
        ]

    constraint_values["default"] = constraint_values[default]

    return constraint_setting, constraint_values


def _constraint_impl(ctx: AnalysisContext) -> list[Provider]:
    constraint_setting, constraint_values = construct_constraint(
        label=ctx.label.raw_target(),
        **obj_to_dict(ctx.attrs, _constraint_attrs.keys()),
    )

    return [
        DefaultInfo(sub_targets=constraint_values),
        constraint_setting,
    ]


constraint = rule(
    impl=_constraint_impl,
    attrs=_constraint_attrs,
    is_configuration_rule=True,
)


def binary_constraint(
    name: str,
    *,
    default: bool = False,
    **kwargs: dict[str, typing.Any],
) -> None:
    for key in kwargs:
        if key in ["values", "nullable"]:
            fail("cannot pass `{}` to binary_constraint()".format(key))

    constraint(
        name=name,
        values=[
            "true",
            "false",
        ],
        default="true" if default else "false",
        **kwargs,
    )
