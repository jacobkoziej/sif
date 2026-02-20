# SPDX-License-Identifier: MPL-2.0
#
# attrs.bzl -- attrs utilities
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def attrs_to_dict(
    attrs: struct,
    keys: list[str] | None = None,
) -> dict[str, typing.Any]:
    if keys == None:
        keys = dir(attrs)

    return {key: getattr(attrs, key) for key in keys}
