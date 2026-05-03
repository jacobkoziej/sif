# SPDX-License-Identifier: MPL-2.0
#
# provider.bzl -- provider utilities
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def get_provider(providers: typing.Any, provider: typing.Any) -> list[Provider]:
    return [p[provider] for p in providers]
