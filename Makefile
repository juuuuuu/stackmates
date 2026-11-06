# Commandes courantes de Stackmates. `make help` les liste.
# Chaque cible appelle un script de tools/ ou Godot : rien ne vit ici.

GODOT ?= godot
GODOT_BIN_DIR ?= $(HOME)/godot-bin
GODOT_VERSION ?= 4.7.2
TEMPLATES_DIR := $(HOME)/.local/share/godot/export_templates/$(GODOT_VERSION).stable
GD_PATHS := sim net ui levels tools tests main.gd
LINT_IMAGE := python:3.12-slim
DOCKER_LINT := docker run --rm -v "$(CURDIR):/w" -w /w $(LINT_IMAGE) sh -c

.DEFAULT_GOAL := help

.PHONY: help run import test smoke lint format typography check build templates levels \
	assets install-godot install-butler itch-setup clean

help: ## Liste les commandes
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-14s %s\n", $$1, $$2}'

run: ## Lance le jeu en fenêtre
	$(GODOT) --path .

import: ## Importe les ressources (après un clone ou un asset régénéré)
	$(GODOT) --headless --path . --import > /dev/null 2>&1

test: ## Tests GUT (tools/test.sh)
	GODOT=$(GODOT) bash tools/test.sh

smoke: ## Smoke réseau : un host et un client headless
	GODOT=$(GODOT) bash tools/smoke.sh

lint: ## gdlint et gdformat --check, via Docker
	$(DOCKER_LINT) 'pip install -q "gdtoolkit==4.*" && gdlint $(GD_PATHS) && gdformat --check $(GD_PATHS)'

format: ## Reformate les .gd avec gdformat, via Docker
	$(DOCKER_LINT) 'pip install -q "gdtoolkit==4.*" && gdformat $(GD_PATHS)'

typography: ## Refuse les caractères bannis dans le texte du dépôt
	bash tools/check_typography.sh

check: lint typography test smoke ## Tout ce que la CI vérifie à chaque push
	bash tools/publish_itch_test.sh

build: templates ## Exporte Linux, Windows et macOS dans export/
	GODOT=$(GODOT) bash tools/export_all.sh

templates: ## Installe les export templates 4.7.2 s'ils manquent
	@test -f "$(TEMPLATES_DIR)/version.txt" || bash tools/install_godot.sh $(GODOT_BIN_DIR) --templates

levels: ## Reconstruit les scènes de niveaux depuis levels/src/*.txt
	$(GODOT) --headless --path . -s tools/build_levels.gd

assets: ## Régénère les images et les sons placeholders
	python3 -I tools/gen_assets.py
	python3 -I tools/gen_audio.py

install-godot: ## Installe Godot 4.7.2 et ses export templates dans ~/godot-bin
	GODOT_VERSION=$(GODOT_VERSION) bash tools/install_godot.sh $(GODOT_BIN_DIR) --templates

install-butler: ## Installe butler (itch.io) dans ~/butler-bin
	bash tools/install_butler.sh

itch-setup: ## Wizard du compte itch.io, du secret et de la variable GitHub
	bash tools/itch_setup.sh

clean: ## Supprime les exports
	rm -rf export
