#!/usr/bin/env bash
# Runs the freelancer script NAME for this OS: scripts/NAME.ps1 under PowerShell on Windows (Git
# Bash), scripts/NAME.sh under bash elsewhere, so SKILL.md and the role prompt use one command
# string on both. Arguments pass through unchanged (same --flags on both).
# Usage: run-for-os.sh NAME [ARGS...]
#   NAME: spawn-freelancer | close-freelancer | list-freelancers | resources | claim
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
name=$1; shift
case "$OSTYPE" in
    msys*|cygwin*)
        exec powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$dir/$name.ps1")" "$@" ;;
    *)
        exec bash "$dir/$name.sh" "$@" ;;
esac
