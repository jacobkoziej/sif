// SPDX-License-Identifier: MPL-2.0
/*
 * hello-world.c -- hello world!
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

#include <pico/stdlib.h>

#include <stdio.h>
#include <stdlib.h>


int main(void)
{
	setup_default_uart();

	printf("Hello, world!\n");

	return EXIT_SUCCESS;
}
