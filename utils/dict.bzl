# SPDX-License-Identifier: MPL-2.0
#
# dict.bzl -- dict utilities
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def obj_to_dict(
    attrs: typing.Any,
    keys: list[str] | None = None,
) -> dict[str, typing.Any]:
    if keys == None:
        keys = dir(attrs)

    return {key: getattr(attrs, key) for key in keys}
