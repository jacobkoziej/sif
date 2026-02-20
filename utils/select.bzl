# SPDX-License-Identifier: MPL-2.0
#
# select.bzl -- select utilities
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def nested_select(
    constraints: list[str],
    d: dict[str, typing.Any],
    *,
    default: typing.Any = None,
) -> Select:
    if default == None:
        default = d.get("DEFAULT")

    selection = select(d)

    for constraint in reversed(constraints):
        selection = select(
            {
                constraint: selection,
                "DEFAULT": default,
            }
        )

    return selection
