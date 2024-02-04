# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

add_executable(
	hello-world
	hello-world.c
)
target_link_libraries(hello-world pico_stdlib)
pico_add_extra_outputs(hello-world)
