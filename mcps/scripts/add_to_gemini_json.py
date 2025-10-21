#!/usr/bin/env python3

import json
import os
import sys


def load_config(path: str) -> dict:
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as handle:
            try:
                return json.load(handle)
            except json.JSONDecodeError as exc:
                raise SystemExit(f"Failed to parse {path}: {exc}") from exc
    return {"mcpServers": {}}


def build_entry(transport: str, payload: list[str]) -> dict:
    if transport == "http":
        if not payload:
            raise SystemExit("HTTP transport requires a URL argument")
        url, *headers = payload
        entry = {"httpUrl": os.path.expandvars(url)}
        header_map: dict[str, str] = {}
        for header in headers:
            if ":" not in header:
                continue
            key, value = header.split(":", 1)
            header_map[key] = os.path.expandvars(value)
        if header_map:
            entry["headers"] = header_map
        return entry

    if transport == "stdio":
        if not payload:
            raise SystemExit("stdio transport requires a command argument")
        command, *args = payload
        return {"command": command, "args": args}

    raise SystemExit(f"Unsupported transport: {transport}")


def main() -> None:
    if len(sys.argv) < 4:
        raise SystemExit(
            "Usage: add_to_gemini_json.py <transport> <server> <config_path> [payload...]"
        )

    transport, server_name, config_arg, *payload = sys.argv[1:]
    config_path = os.path.expanduser(config_arg)
    os.makedirs(os.path.dirname(config_path), exist_ok=True)

    config = load_config(config_path)
    config.setdefault("mcpServers", {})
    config["mcpServers"][server_name] = build_entry(transport, payload)

    with open(config_path, "w", encoding="utf-8") as handle:
        json.dump(config, handle, indent=2)
        handle.write("\n")


if __name__ == "__main__":
    main()
