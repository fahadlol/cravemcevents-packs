"""Strict structural audit for the CraveMC resource pack."""

from __future__ import annotations

import argparse
import json
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path

from PIL import Image


RESOURCE_LOCATION = re.compile(r"^[a-z0-9_.-]+:[a-z0-9_./-]+$")
NAMESPACE = re.compile(r"^[a-z0-9_.-]+$")


class DuplicateKeyError(ValueError):
    pass


def strict_object(pairs):
    counts = Counter(key for key, _ in pairs)
    duplicates = sorted(key for key, count in counts.items() if count > 1)
    if duplicates:
        raise DuplicateKeyError("duplicate keys: " + ", ".join(duplicates))
    return dict(pairs)


def is_power_of_two(value: int) -> bool:
    return value > 0 and value & (value - 1) == 0


def audit(pack: Path, archive_path: Path | None) -> int:
    errors: list[str] = []
    warnings: list[str] = []
    parsed: dict[Path, object] = {}

    for path in sorted(pack.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(pack).as_posix()
        if relative.startswith("assets/") or "/assets/" in relative:
            parts = relative.split("/")
            assets_index = parts.index("assets")
            if len(parts) <= assets_index + 1 or not NAMESPACE.fullmatch(parts[assets_index + 1]):
                errors.append(f"invalid namespace path: {relative}")
            if relative != relative.lower():
                errors.append(f"uppercase character in resource path: {relative}")

        if path.suffix == ".json" or path.name.endswith(".mcmeta"):
            try:
                parsed[path] = json.loads(
                    path.read_text(encoding="utf-8-sig"), object_pairs_hook=strict_object
                )
            except Exception as exc:
                errors.append(f"invalid JSON {relative}: {exc}")

        if path.suffix.lower() == ".png":
            try:
                with Image.open(path) as image:
                    image.verify()
                with Image.open(path) as image:
                    width, height = image.size
                if width <= 0 or height <= 0:
                    errors.append(f"invalid PNG dimensions {relative}: {width}x{height}")
                if "/textures/block/" in f"/{relative}" and (
                    not is_power_of_two(width) or not is_power_of_two(height)
                ):
                    warnings.append(f"non-power-of-two block texture {relative}: {width}x{height}")
            except Exception as exc:
                errors.append(f"invalid PNG {relative}: {exc}")

    for path, data in parsed.items():
        relative = path.relative_to(pack).as_posix()
        if "/models/" in f"/{relative}" and isinstance(data, dict):
            for index, element in enumerate(data.get("elements", [])):
                if not isinstance(element, dict):
                    continue
                for key in ("from", "to"):
                    coords = element.get(key)
                    if isinstance(coords, list) and len(coords) == 3:
                        if any(not isinstance(v, (int, float)) or v < -16 or v > 32 for v in coords):
                            errors.append(
                                f"model coordinate outside [-16,32] {relative} "
                                f"element {index} {key}={coords}"
                            )

        def inspect(value, parent_key=None):
            if isinstance(value, dict):
                for key, child in value.items():
                    inspect(child, key)
            elif isinstance(value, list):
                for child in value:
                    inspect(child, parent_key)
            elif (
                isinstance(value, str)
                and parent_key != "chars"
                and ":" in value
                and not RESOURCE_LOCATION.fullmatch(value)
            ):
                if not value.startswith(("http:", "https:")) and " " not in value:
                    warnings.append(f"suspicious resource location {relative}: {value}")

        inspect(data)

        if not isinstance(data, dict):
            continue
        parts = relative.split("/")
        assets_index = parts.index("assets") if "assets" in parts else -1
        namespace = parts[assets_index + 1] if assets_index >= 0 and len(parts) > assets_index + 1 else "minecraft"

        if "/models/" in f"/{relative}":
            for texture in data.get("textures", {}).values():
                if not isinstance(texture, str) or texture.startswith("#") or ":" not in texture:
                    continue
                texture_namespace, texture_path = texture.split(":", 1)
                local = pack / "assets" / texture_namespace / "textures" / f"{texture_path}.png"
                if texture_namespace != "minecraft" and not local.is_file():
                    errors.append(f"missing model texture {relative}: {texture}")

        if "/font/" in f"/{relative}":
            for provider in data.get("providers", []):
                if not isinstance(provider, dict) or provider.get("type") != "bitmap":
                    continue
                texture = provider.get("file", "")
                if ":" not in texture:
                    continue
                texture_namespace, texture_path = texture.split(":", 1)
                local = pack / "assets" / texture_namespace / "textures" / texture_path
                if texture_namespace != "minecraft" and not local.is_file():
                    errors.append(f"missing font bitmap {relative}: {texture}")

        if "/particles/" in f"/{relative}":
            for texture in data.get("textures", []):
                if not isinstance(texture, str) or ":" not in texture:
                    continue
                texture_namespace, texture_path = texture.split(":", 1)
                local = pack / "assets" / texture_namespace / "textures" / "particle" / f"{texture_path}.png"
                if texture_namespace != "minecraft" and not local.is_file():
                    errors.append(f"missing particle texture {relative}: {texture}")

    metadata_path = pack / "pack.mcmeta"
    metadata = parsed.get(metadata_path)
    if not isinstance(metadata, dict) or not isinstance(metadata.get("pack"), dict):
        errors.append("pack.mcmeta is missing a valid pack object")
    else:
        section = metadata["pack"]
        if section.get("pack_format") != 75:
            errors.append("pack.pack_format must remain 75 for Minecraft 1.21.11")
        if "supported_formats" in section:
            errors.append("pack.supported_formats is not allowed when resource min_format is above 64")
        if section.get("min_format") != 75:
            errors.append("pack.min_format must be 75")
        if section.get("max_format") != [97, 1]:
            errors.append("pack.max_format must be [97, 1]")

    for path, data in parsed.items():
        if path.name != "sounds.json" or not isinstance(data, dict):
            continue
        namespace = path.parent.name
        for event, definition in data.items():
            if not isinstance(definition, dict):
                continue
            for sound in definition.get("sounds", []):
                if isinstance(sound, str):
                    name, sound_type = sound, "file"
                elif isinstance(sound, dict):
                    name = sound.get("name", "")
                    sound_type = sound.get("type", "file")
                else:
                    continue
                if sound_type != "file" or not name:
                    continue
                sound_namespace, separator, sound_path = name.partition(":")
                if not separator:
                    sound_namespace, sound_path = namespace, sound_namespace
                local = pack / "assets" / sound_namespace / "sounds" / f"{sound_path}.ogg"
                custom_minecraft_path = sound_namespace == "minecraft" and (
                    sound_path.startswith("custom/") or "/" not in sound_path
                )
                if not local.is_file() and (sound_namespace != "minecraft" or custom_minecraft_path):
                    errors.append(
                        f"missing sound file for {namespace}:{event}: "
                        f"{sound_namespace}:{sound_path}"
                    )

    if archive_path:
        try:
            with zipfile.ZipFile(archive_path) as archive:
                names = archive.namelist()
                roots = {name.split("/", 1)[0] for name in names if name and not name.startswith("__MACOSX/")}
                if "pack.mcmeta" not in names or "pack.png" not in names or "assets" not in roots:
                    errors.append(f"ZIP has an invalid root layout: {sorted(roots)}")
                if any(name.count("/") and name.split("/", 1)[1] == "pack.mcmeta" for name in names):
                    errors.append("ZIP contains a nested wrapper directory with pack.mcmeta")
                bad = archive.testzip()
                if bad:
                    errors.append(f"ZIP CRC failure: {bad}")
        except Exception as exc:
            errors.append(f"invalid ZIP {archive_path}: {exc}")

    print(f"JSON/MCMeta files parsed: {len(parsed)}")
    print(f"Warnings: {len(warnings)}")
    for warning in sorted(set(warnings)):
        print(f"WARN: {warning}")
    print(f"Errors: {len(errors)}")
    for error in sorted(set(errors)):
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("pack", type=Path)
    parser.add_argument("--zip", type=Path)
    args = parser.parse_args()
    sys.exit(audit(args.pack, args.zip))
