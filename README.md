# NitrOS-9 for QEMU

NitrOS-9 is a community-maintained distribution of Microware OS-9 for the
Motorola 6809 and Hitachi 6309 processors. It supports the Tandy Color
Computer family and several other 6809-based systems.

This fork of [NitrOS-9](https://github.com/nitros9project/nitros9) adds
drivers for the [Turbo9/6809/6309
fork of QEMU](https://github.com/jasonsikes/qemu). These drivers
were created for efficiency and convenience. Most notably:

* NitrOS-9's system time is derived from the host's system clock.
* A virtual console using QEMU's standard input and output. To use it, type:
`shell i=/t0 &` at a NitrOS-9 prompt.
* The virtual disk drivers are much more efficient than hardware disk drives or hardware emulation.

This fork also provides a recipe for creating a bootable floppy image suitable
for the 6809/6309/Turbo9 port of QEMU.

| OS-9 module | Virtual Hardware | QEMU option |
| --- | --- | --- |
| `/DD`, `/D0` | Virt disk unit 0 | first `-drive` (boot image) |
| `/H0` | Virt disk unit 1 | second `-drive` (optional) |
| `/T0` | Virt console | `-serial` |
| `Clock2` | Virt RTC | `-rtc` |

The drivers are in `level2/qemu/modules/`. Port and device names can be
found in `defs/qemu.d`. The qemu-specific floppy image recipe is in `recipes/coco3/floppy_qemu`.

## Repository layout

- `level1/`, `level2/`, and `level3/` contain operating-system source arranged
  by OS level and target platform.
- `defs/` contains shared assembler definitions.
- `lib/` contains shared libraries.
- `recipes/` contains the supported disk-image and distribution builds.
- `scripts/` contains repository maintenance, formatting, and
  reverse-engineering utilities.
- `archive/` preserves unsupported and historical material.

See [Repository layout](docs/repository-layout.md) for details and
[Supported ports](docs/supported-ports.md) for the current target matrix.

## Building

Install the following tools and ensure they are on `PATH`:

- [LWTOOLS](http://lwtools.projects.l-w.ca), including `lwasm`, `lwlink`, and
  `lwar`
- [ToolShed](https://github.com/n6il/toolshed), including the `os9` utilities
- `make`

Recipes that package BASIC09 require a sibling checkout of
[nitros9-languages](https://github.com/nitros9project/nitros9-languages).
Some expanded recipes also use
[nitros9-apps](https://github.com/nitros9project/nitros9-apps):

```text
parent/
  nitros9/
  nitros9-apps/
  nitros9-languages/
```

Set `NITROS9_APPS_DIR` or `LANGUAGES` to use another layout.

To build the CoCo 3 Level 2 floppy image with QEMU drivers:

```sh
export NITROS9DIR=$HOME/nitros9
make -C recipes/coco3/floppy_qemu
```

Each recipe writes its output into its own directory. See the
[recipe documentation](recipes/README.md) for the available builds. The QEMU
floppy image will be located at `recipes/coco3/floppy_qemu/l2_coco3_qemu.dsk`.

## Booting

Boot the floppy image with the companion [Turbo9/6809/6309
fork of QEMU](https://github.com/jasonsikes/qemu).

```sh
qemu-system-m6809 -M coco3 \
    -drive file=recipes/coco3/floppy_qemu/l2_coco3_qemu.dsk,format=raw \
    -serial stdio \
    -rtc base=localtime
```

For more information about booting QEMU, see the
[companion repository's README](https://github.com/jasonsikes/qemu).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution and commit guidance.

Historical release notes and migrated project files are retained under
[`archive/project-history`](archive/project-history/README.md).

