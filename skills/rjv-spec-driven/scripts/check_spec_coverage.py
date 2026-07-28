#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path


SIMPLE_CRITERION = re.compile(r"^\s*-\s+([A-Z][A-Z0-9]*\d+)\.\s+")
BOLD_CRITERION = re.compile(r"^\s*-\s+\*\*([A-Z][A-Z0-9]*\d+)\s+[—-]")
TEXT_EXTENSIONS = {
    ".cjs",
    ".cs",
    ".dart",
    ".ex",
    ".exs",
    ".feature",
    ".go",
    ".java",
    ".js",
    ".jsx",
    ".kt",
    ".mjs",
    ".php",
    ".py",
    ".rb",
    ".rs",
    ".scala",
    ".sql",
    ".swift",
    ".ts",
    ".tsx",
    ".vue",
}


def usage() -> None:
    print(
        "usage: check_spec_coverage.py <spec.md> <test-root> [<test-root> ...]\n"
        "\n"
        "Roots must contain tests only — any ID mentioned in a scanned file counts\n"
        "as a mapping, so pointing at a source tree will report false coverage.",
        file=sys.stderr,
    )


def criteria(spec: Path) -> tuple[list[str], list[str]]:
    found: list[str] = []

    for line in spec.read_text(encoding="utf-8").splitlines():
        if "RETIRED:" in line:
            continue

        match = SIMPLE_CRITERION.match(line) or BOLD_CRITERION.match(line)

        if match:
            found.append(match.group(1))

    duplicates = sorted({criterion for criterion in found if found.count(criterion) > 1})

    return found, duplicates


def test_files(roots: list[Path]) -> list[Path]:
    files: set[Path] = set()

    for root in roots:
        if not root.exists():
            raise FileNotFoundError(f"test root does not exist: {root}")

        candidates = [root] if root.is_file() else root.rglob("*")

        for candidate in candidates:
            if candidate.is_file() and candidate.suffix.lower() in TEXT_EXTENSIONS:
                files.add(candidate)

    return sorted(files)


def references(criterion: str, files: list[Path]) -> list[Path]:
    token = re.compile(rf"(?<![A-Z0-9]){re.escape(criterion)}(?![A-Z0-9])")
    matched: list[Path] = []

    for path in files:
        try:
            source = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        if token.search(source):
            matched.append(path)

    return matched


def main() -> int:
    if len(sys.argv) < 3:
        usage()
        return 2

    spec = Path(sys.argv[1])
    roots = [Path(argument) for argument in sys.argv[2:]]

    if not spec.is_file():
        print(f"spec does not exist: {spec}", file=sys.stderr)
        return 2

    criterion_ids, duplicates = criteria(spec)

    if not criterion_ids:
        print("no acceptance-criterion IDs found", file=sys.stderr)
        return 1

    failures: list[str] = []

    if duplicates:
        failures.append(f"duplicate criterion IDs: {', '.join(duplicates)}")

    try:
        files = test_files(roots)
    except FileNotFoundError as error:
        print(str(error), file=sys.stderr)
        return 2

    if not files:
        failures.append("no test files found in supplied roots")

    for criterion in dict.fromkeys(criterion_ids):
        matched = references(criterion, files)

        if not matched:
            failures.append(f"{criterion}: no mapped test reference")
            continue

        print(f"{criterion}: {', '.join(str(path) for path in matched)}")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)

        return 1

    print(f"OK: {len(set(criterion_ids))} criteria mapped to tests")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
