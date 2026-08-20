#!/usr/bin/env bash
#
# Checks the cui end of the Companion pipe: describe (canonical nodes) →
# snapshot → wire → inflate → NodeRenderer → a tap fired through the
# renderer's own event path reaches the original closure via the
# ActionTable. Judged on the exit code — the check prints its verdicts.
#
#   ./tests/describe.sh

set -u
cd "$(dirname "$0")/.."

haxe -cp tests -cp src \
	-lib mui -lib kui -lib rui -lib nui \
	-D mui_backend=cui \
	--macro "mui.macros.Bind.all()" \
	--macro "cui.kui.Platform.registerWithKui()" \
	-main DescribeCheck --interp
