# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>

set(SIF_SRC_DIR "$ENV{SIF_SRC_DIR}")

set(SIF_SRC
	"march/rp2040/port-asm.s"
	"march/rp2040/port.c"
)
list(TRANSFORM SIF_SRC PREPEND "${SIF_SRC_DIR}/src/")

set(SIF_INCLUDE_DIRECTORIES
	"march/rp2040/include"
)
list(TRANSFORM SIF_INCLUDE_DIRECTORIES PREPEND "${SIF_SRC_DIR}/include/sif/")
list(APPEND SIF_INCLUDE_DIRECTORIES "${SIF_SRC_DIR}/include")

add_library(sif STATIC ${SIF_SRC})
target_include_directories(sif PUBLIC ${SIF_INCLUDE_DIRECTORIES})


set(SIF_CC_AS_FLAGS ${SIF_INCLUDE_DIRECTORIES})
list(TRANSFORM SIF_CC_AS_FLAGS PREPEND "-Wa,-I")
target_compile_options(sif BEFORE PRIVATE ${SIF_CC_AS_FLAGS})
