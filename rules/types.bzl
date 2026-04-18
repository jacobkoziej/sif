# SPDX-License-Identifier: MPL-2.0
#
# types.bzl -- rule independent types
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

HexInfo = provider(
    fields={
        "hex": provider_field(Artifact),
    },
)
