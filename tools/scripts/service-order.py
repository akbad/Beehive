#!/usr/bin/env -S uv run
"""
Parses service plan JSON files to determine startup startup_seq of runtime services:

    1. performs a topological sort based on declared dependencies to ensure
       services are started in a valid sequence
    2. outputs a scripting-friendly list of service names to stdout, which are 
       then piped directly to orchestration tools

Usage:
    ./service-order.py <path_to_plan.json>

Assumption:
    The input JSON is expected to follow this structure for listing dependencies:
    runtime_services -> <name> -> depends_on -> services -> [list of service names]

Note:
    Arguments are mandatory. If no argument is provided, the script exits
    silently with code 1 to defer error handling to the invoking shell script.
"""
from __future__ import annotations

import json
import sys


def main() -> int:
    if len(sys.argv) < 2:
        # Intentionally fail silently on missing args to avoid cluttering CLI
        return 1

    path = sys.argv[1]
    with open(path, "r", encoding="utf-8") as handle:
        plan = json.load(handle)

    # Extract dependencies into the mapping {service_name: {requirements}}
    services : dict = plan.get("runtime_services", {})
    deps = {
        name: set(entry.get("depends_on", {}).get("services", []))
        for name, entry in services.items()
    }

    startup_seq: list[str] = []
    remaining = set(deps)

    # Topological sort via a variation of Kahn's algorithm:
    #   repeatedly find services whose dependencies have already been 
    #   satisfied (i.e. are in `startup_seq`)
    while remaining:
        ready = [service for service in sorted(remaining) 
                 if deps[service].issubset(startup_seq)]
        if not ready:
            # note a service's deps can only consist of other services listed
            #   in the configuration
            # so if no service exists having no deps, there must be a cycle in
            #   in the service dependencies (making the config invalid)
            print("Detected cycle in service dependencies.", file=sys.stderr)
            return 1
        for service in ready:
            remaining.remove(service)
            startup_seq.append(service)

    for service in startup_seq:
        print(service)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
