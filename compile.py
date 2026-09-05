#!/usr/bin/env python3
"""
Cross-platform LaTeX build script for an IEEE paper using pdflatex + biber.

Requirements:
- Python 3
- pdflatex installed and available in PATH
- biber installed and available in PATH

Usage:
    python compile.py
    python compile.py main.tex
    python compile.py main.tex --no-clean-after
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


BUILD_EXTENSIONS = [
    "aux",
    "bbl",
    "bcf",
    "blg",
    "log",
    "out",
    "run.xml",
    "toc",
    "lof",
    "lot",
    "fls",
    "fdb_latexmk",
    "synctex.gz",
]


def warn(message: str) -> None:
    print(f"WARNING: {message}", file=sys.stderr)


def info(message: str) -> None:
    print(message)


def check_tool_exists(tool_name: str) -> bool:
    return shutil.which(tool_name) is not None


def clean_build_files(project_dir: Path, job_name: str) -> None:
    for ext in BUILD_EXTENSIONS:
        path = project_dir / f"{job_name}.{ext}"
        try:
            if path.exists():
                path.unlink()
        except OSError as exc:
            warn(f"Could not delete {path}: {exc}")


def run_command(command: list[str], cwd: Path) -> None:
    info("")
    info("Running: " + " ".join(command))
    result = subprocess.run(command, cwd=str(cwd))

    if result.returncode != 0:
        raise RuntimeError(
            f"Command failed with exit code {result.returncode}: {' '.join(command)}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compile a LaTeX project with pdflatex and biber."
    )
    parser.add_argument(
        "main_file",
        nargs="?",
        default="main.tex",
        help="Main .tex file to compile. Default: main.tex",
    )
    parser.add_argument(
        "--no-clean-before",
        action="store_true",
        help="Do not delete old build files before compiling.",
    )
    parser.add_argument(
        "--no-clean-after",
        action="store_true",
        help="Keep build files after successful compilation.",
    )
    parser.add_argument(
        "--extra-biber",
        action="store_true",
        help="Run biber a second time before the final pdflatex passes.",
    )
    args = parser.parse_args()

    main_file = Path(args.main_file).resolve()
    project_dir = main_file.parent
    job_name = main_file.stem
    output_pdf = project_dir / f"{job_name}.pdf"

    if not main_file.exists():
        warn(f"Main TeX file not found: {main_file}")
        return 1

    missing_tools = [
        tool for tool in ("pdflatex", "biber") if not check_tool_exists(tool)
    ]

    if missing_tools:
        warn(
            "Missing required tool(s): "
            + ", ".join(missing_tools)
            + ". Install LaTeX and Biber, and make sure they are available in PATH."
        )
        return 1

    if not (project_dir / "Bibliography.bib").exists():
        warn(
            "Bibliography.bib was not found next to the main file. "
            "Compilation may still work, but biber can fail if the document expects it."
        )

    try:
        if not args.no_clean_before:
            info("Cleaning old build files...")
            clean_build_files(project_dir, job_name)

        # Standard biblatex sequence:
        # pdflatex -> biber -> pdflatex -> pdflatex
        run_command(
            ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", main_file.name],
            cwd=project_dir,
        )

        run_command(["biber", job_name], cwd=project_dir)

        run_command(
            ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", main_file.name],
            cwd=project_dir,
        )

        if args.extra_biber:
            run_command(["biber", job_name], cwd=project_dir)

        run_command(
            ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", main_file.name],
            cwd=project_dir,
        )

        if not args.no_clean_after:
            info("")
            info("Cleaning build files...")
            clean_build_files(project_dir, job_name)

    except RuntimeError as exc:
        warn(str(exc))
        warn("Build failed. Log files were kept so you can inspect the error.")
        return 1

    info("")
    if output_pdf.exists():
        info(f"Done. Output PDF: {output_pdf}")
        return 0

    warn(f"Build finished, but output PDF was not found: {output_pdf}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
