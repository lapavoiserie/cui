#!/bin/sh
# `ui(<VStack>…)` against cui's own declarations: what compiles, and what does not.
#
#   ./tests/markup/check.sh
cd "$(dirname "$0")/../.."
fails=0
common="-cp src -lib rui -lib nui -lib mui -D mui_backend=cui --macro cui.nui.Vocabulary.registerWithMui()"

haxe $common -cp tests/markup -main MarkupCheck --interp || fails=$((fails + 1))

echo ""
out=$(haxe $common -cp tests/markup/refused -main BadAttr --interp 2>&1)
if echo "$out" | grep -q 'n.a pas d.attribut "onTogle"'; then
	echo "ok   a misspelt attribute is refused, and the message lists what is accepted"
else
	echo "FAIL onTogle was not refused:"; echo "$out"; fails=$((fails + 1))
fi

out=$(haxe $common -cp tests/markup/refused -main BadTag --interp 2>&1)
if echo "$out" | grep -q 'Hologramme'; then
	echo "ok   a tag nothing declares is refused by name"
else
	echo "FAIL Hologramme was not refused:"; echo "$out"; fails=$((fails + 1))
fi

echo ""
[ "$fails" -eq 0 ] && echo "all good" || echo "$fails failed"
exit "$fails"
