#!/usr/bin/env bash
# Refuse, dans le texte du dépôt, le tiret cadratin (U+2014), le demi-cadratin
# (U+2013), le point médian (U+00B7), la puce (U+2022) et les points de
# suspension en un caractère (U+2026). Les motifs sont les octets UTF-8 de
# chaque caractère, cherchés en chaîne fixe : même résultat avec GNU grep et ugrep.
set -u
cd "$(dirname "$0")/.."
if grep -rnF \
	-e "$(printf '\xe2\x80\x94')" -e "$(printf '\xe2\x80\x93')" -e "$(printf '\xc2\xb7')" \
	-e "$(printf '\xe2\x80\xa2')" -e "$(printf '\xe2\x80\xa6')" \
	README.md CLAUDE.md GLOSSARY.md docs/*.md docs/adr main.gd \
	sim net ui levels tools tests locale .github; then
	echo "check_typography: caractères bannis trouvés"
	exit 1
fi
echo "check_typography: OK"
