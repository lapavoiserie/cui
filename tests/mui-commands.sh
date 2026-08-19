#!/usr/bin/env bash
#
# Checks the Commands surface on cui: MuiCommandsCheck constructs a real
# mui application (full chain: Bind, @:surface collection) and drives
# handleEvent with synthesized keys. Judged on the exit code — the check
# prints its own verdicts.
#
#   ./tests/mui-commands.sh

set -u
cd "$(dirname "$0")/.."

haxe -cp tests -cp src \
	-lib mui -lib kui -lib rui -lib nui \
	-D mui_backend=cui \
	--macro "mui.macros.Bind.all()" \
	--macro "cui.kui.Platform.registerWithKui()" \
	-main MuiCommandsCheck --interp
