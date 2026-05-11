# pokecrystal

Static recompilation of Pokemon Crystal into portable C, built with
[GB-Recomp/gb-recompiled](https://github.com/GB-Recomp/gb-recompiled).

This repo ships pre-generated C sources so it builds out of the box —
you don't need an asm toolchain or the pret/pokecrystal decompilation just
to play.

## Build

You need a C/C++ compiler, CMake 3.16+, SDL2, libcurl, and OpenGL ES 2.
CMake fetches `gb-recompiled` automatically (no manual setup).

```sh
mkdir build && cd build
cmake ..
cmake --build . -j$(nproc)
```

This produces a `pokecrystal` executable.

## Run

The runtime needs a ROM the first time it boots (it extracts assets into
`assets/pokecrystal/` and then runs from there on subsequent launches).

Drop a Pokemon Crystal ROM at `roms/pokecrystal.gbc` next to the executable:

```sh
mkdir -p roms
cp /path/to/pokecrystal.gb roms/pokecrystal.gbc
./pokecrystal
```

The launcher auto-starts when only one game is registered, so you go
straight into Red. Battery RAM saves to `pokecrystal.sav` next to the
binary. Press Esc in-game for the settings menu (palette, audio,
savestates, **Restart Game**, etc.).

## Regenerating the C sources

If you want to rebuild the C from scratch — bump `gb-recompiled`, pick
up a recompiler change, or tweak the analyzer — run:

```sh
tools/regen.sh /path/to/pret/pokecrystal /path/to/gb-recompiled
```

That re-builds the ROM via the pret toolchain (requires `rgbds`), then
invokes `gbrecomp` with the same flags the compilation uses, and copies
the freshly generated `pokecrystal_*.c` files into this repo. Verify with
`cmake --build .` and commit.

## In a compilation

If you're building a multi-cart compilation that wants to include Red,
add this repo via `FetchContent` in your top-level CMakeLists:

```cmake
FetchContent_Declare(pokecrystal
    GIT_REPOSITORY https://github.com/GB-Recomp/pokecrystal.git
    GIT_TAG main
)
FetchContent_MakeAvailable(pokecrystal)
# Now link the `pokecrystal_cart` target into your launcher executable
# and call pokecrystal_main(argc, argv) from your launcher's g_games[].
```

The standalone `pokecrystal` executable is only built when this repo is the
top-level project, so consuming it as a subdir doesn't produce a
conflicting executable target.
