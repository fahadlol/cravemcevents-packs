#!/usr/bin/env python3
from __future__ import annotations

import argparse
import stat
import zipfile
from pathlib import Path


PACK_ENTRIES = (
    "assets",
    "shaders",
    "overlay_1_20_2",
    "overlay_1_21_4",
    "overlay_1_21_11",
    "overlay_26",
    "overlay_26_2",
    "overlay_26_3",
    "pack.mcmeta",
    "pack.png",
)
ZIP_TIMESTAMP = (2026, 1, 1, 0, 0, 0)
TEXT_SUFFIXES = {".fsh", ".glsl", ".jem", ".json", ".lang", ".mcmeta", ".properties", ".txt", ".vsh"}


def pack_files(root: Path):
    for entry_name in PACK_ENTRIES:
        entry = root / entry_name
        if not entry.exists():
            raise FileNotFoundError(f"missing pack entry: {entry}")
        if entry.is_file():
            yield entry
            continue
        yield from sorted(path for path in entry.rglob("*") if path.is_file())


def build(root: Path, output: Path) -> None:
    root = root.resolve()
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(
        output,
        "w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as archive:
        for path in pack_files(root):
            relative = path.relative_to(root).as_posix()
            info = zipfile.ZipInfo(relative, ZIP_TIMESTAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            contents = path.read_bytes()
            if path.suffix.lower() in TEXT_SUFFIXES:
                contents = contents.replace(b"\r\n", b"\n")
            archive.writestr(info, contents, compresslevel=9)


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the deterministic CraveMC resource-pack ZIP")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    build(args.source, args.output)
    print(args.output.resolve())


if __name__ == "__main__":
    main()
