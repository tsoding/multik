# multik

Animation Framework

[![MULTIK DEMO](https://img.youtube.com/vi/6QAeNTOdhsk/0.jpg)](https://www.youtube.com/watch?v=6QAeNTOdhsk)

## Dependencies

- [OCaml]
- [gcc]
- [SDL2]
- [cairo]
- [ffmpeg]

Note that the only supported OS at the moment is Linux. Track [#49] for Windows support.

### NixOS

For [NixOS] we have a development environment defined in [default.nix]
with all of the required dependencies. You can enter the environment
with nix-shell command:

```console
$ nix-shell
```

### Ubuntu

```console
$ sudo apt-get install gcc ocaml libsdl2-dev libcairo2-dev
```

## Quick Start

```console
$ nix-shell        # For NixOS
$ make
$ ./multik preview samples/arkanoid.cmo
$ ./multik render samples/arkanoid.cmo arkanoid.mp4
```

## Support

You can support my work via

- Twitch channel: https://www.twitch.tv/subs/tsoding
- Patreon: https://www.patreon.com/tsoding

[OCaml]: http://www.ocaml.org/
[gcc]: https://gcc.gnu.org/
[SDL2]: https://www.libsdl.org/
[cairo]: https://www.cairographics.org/
[ffmpeg]: https://ffmpeg.org/
[#49]: https://github.com/tsoding/multik/issues/49
[NixOS]: https://nixos.org/
[default.nix]: ./default.nix
