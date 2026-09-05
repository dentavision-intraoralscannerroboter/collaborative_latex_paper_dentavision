#!/usr/bin/env bash
#
# Cross-platform LaTeX build wrapper for compile.py
#
# Handles every contingency: missing Python, missing compile.py,
# missing pdflatex/biber. Delegates the actual build to compile.py
# and propagates its exit code.
#
# Usage:
#     ./compile.sh
#     ./compile.sh main.tex
#     ./compile.sh main.tex --no-clean-after

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# 1. Find Python
# ---------------------------------------------------------------------------
PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

if [[ -z "$PYTHON" ]]; then
    cat >&2 <<'EOF'
ERROR: Python was not found in PATH.

Please install Python 3, then re-run this script:
  - Ubuntu/Debian:  sudo apt install python3
  - Fedora:         sudo dnf install python3
  - Arch:           sudo pacman -S python
  - Windows:        install from https://www.python.org/downloads/
                   (make sure "Add Python to PATH" is checked)
EOF
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Ensure compile.py is present
# ---------------------------------------------------------------------------
if [[ ! -f "compile.py" ]]; then
    cat >&2 <<'EOF'
ERROR: compile.py not found next to this script.

Make sure both files (compile.sh and compile.py) are in the same directory,
then re-run this script.
EOF
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. Check required LaTeX tools
# ---------------------------------------------------------------------------
MISSING_TOOLS=()
command -v pdflatex >/dev/null 2>&1 || MISSING_TOOLS+=("pdflatex")
command -v biber    >/dev/null 2>&1 || MISSING_TOOLS+=("biber")

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    cat >&2 <<'EOF'
ERROR: The following required tool(s) are missing from PATH:
EOF
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool" >&2
    done
    cat >&2 <<'EOF'

Please install a full TeX distribution that includes pdflatex and biber:
  - Ubuntu/Debian:
      sudo apt install texlive-latex-extra biber
  - Fedora:
      sudo dnf install texlive-scheme-full biber
  - Arch:
      sudo pacman -S texlive-most biber
  - Windows (MiKTeX):
      winget install MiKTeX.MiKTeX
      then verify:  pdflatex --version  and  biber --version
  - macOS (MacTeX):
      brew install --cask mactex
Afterwards, open a new terminal so PATH picks up the tools, then re-run.
EOF
    exit 1
fi

# ---------------------------------------------------------------------------
# 4. Run the build
# ---------------------------------------------------------------------------
"$PYTHON" compile.py "$@"
exit $?
