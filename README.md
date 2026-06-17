# sif

> a preemptive rtos

## Getting Started

This project uses a [Nix] [flake] to manage dependencies and [Buck2] to build.
You can drop into a development shell with `nix develop`, or if you have [`direnv`] enabled, run `direnv allow`.

### Building

You'll need to specify relevant [configuration modifiers] for your microcontroller.
You can find available configurations and constraints under [`/cfg`] and [`/constraints`] respectively.

For example, here's how you'd build sif for the [rp2350a]:

```
$ buck2 build --modifier sif//cfg/mcu/raspberry-pi:rp2350a //targets:vmsif.elf
```

> [!TIP]
>
> Instead of having to specify modifiers for every build, you can set defaults in your `.buckconfig.local`:
>
> ```ini
> [cfg_modifiers]
> modifiers = sif//cfg/mcu/raspberry-pi:rp2350a
> ```
>
> Invocations of `buck2` can then be as follows:
>
> ```
> $ buck2 build //targets:vmsif.elf
> ```

## Copyright & Licensing

Copyright (C) 2024--2026 Jacob Koziej [`<jacobkoziej@gmail.com>`]

Distributed under the [MPL 2.0].

[buck2]: https://buck2.build/
[configuration modifiers]: https://buck2.build/docs/concepts/modifiers/
[flake]: https://wiki.nixos.org/wiki/Flakes
[mpl 2.0]: ./LICENSE
[nix]: https://nixos.org/
[rp2350a]: https://www.raspberrypi.com/products/rp2350/
[`/cfg`]: ./cfg
[`/constraints`]: ./constraints
[`<jacobkoziej@gmail.com>`]: mailto:jacobkoziej@gmail.com
[`direnv`]: https://direnv.net/
