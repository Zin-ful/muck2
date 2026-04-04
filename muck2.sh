#!/bin/sh
printf '\033c\033]0;%s\a' muck2
base_path="$(dirname "$(realpath "$0")")"
"$base_path/muck2.x86_64" "$@"
