"""Validate the shared subset of personal skill manifests."""

import re
from pathlib import Path

try:
    import yaml
except ModuleNotFoundError:
    raise SystemExit("PyYAML is required: install python-yaml (Arch) or python3-yaml (Mint).") from None


NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
FIELDS = {"name", "description", "license", "compatibility", "metadata"}


class UniqueLoader(yaml.SafeLoader):
    pass


def unique_mapping(loader, node, deep=False):
    result = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if not isinstance(key, str) or key in result:
            raise ValueError(f"duplicate or non-string manifest key: {key!r}")
        result[key] = loader.construct_object(value_node, deep=deep)
    return result


UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_mapping)


def read_manifest(directory: Path) -> dict:
    """Return validated metadata, or raise ValueError with a repairable error."""
    text = (directory / "SKILL.md").read_text()
    match = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.DOTALL)
    if not match:
        raise ValueError("SKILL.md needs YAML front matter")
    try:
        meta = yaml.load(match.group(1), Loader=UniqueLoader)
    except yaml.YAMLError as error:
        raise ValueError(f"invalid YAML: {error}") from error
    if not isinstance(meta, dict):
        raise ValueError("front matter must be a mapping")
    name = meta.get("name")
    if not isinstance(name, str) or not NAME.fullmatch(name) or len(name) > 64:
        raise ValueError("name must be 1–64 lowercase letters/digits with single hyphens")
    if name != directory.name:
        raise ValueError(f"name {name!r} does not match directory {directory.name!r}")
    description = meta.get("description")
    if not isinstance(description, str) or not 1 <= len(description.strip()) <= 1024:
        raise ValueError("description must contain 1–1024 characters")
    if set(meta) - FIELDS:
        raise ValueError(f"provider-specific or unknown fields: {', '.join(sorted(set(meta) - FIELDS))}")
    for key in ("license", "compatibility"):
        if key in meta and not isinstance(meta[key], str):
            raise ValueError(f"{key} must be a string")
    metadata = meta.get("metadata", {})
    if not isinstance(metadata, dict) or any(not isinstance(v, str) for v in metadata.values()):
        raise ValueError("metadata must map strings to strings")
    if not text[match.end():].strip():
        raise ValueError("SKILL.md needs workflow instructions after front matter")
    nested = [p for p in directory.rglob("SKILL.md") if p != directory / "SKILL.md"]
    if nested:
        raise ValueError("nested SKILL.md files are separate skills; move them out")
    return meta
