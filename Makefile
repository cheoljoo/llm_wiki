CONFIG_DIR := $(HOME)/.config/llm_wiki
COMMANDS_DIR := $(HOME)/.claude/commands
REPO_PATH := $(CURDIR)

.DEFAULT_GOAL := help

.PHONY: help install install-repo-path install-command update uninstall

help:
	@echo "make install           - repo_path 설정 + wiki-log 커맨드 설치 (최초 1회)"
	@echo "make update            - wiki-log 커맨드만 다시 복사 (tooling/commands/wiki-log.md가 바뀐 뒤 git pull 시)"
	@echo "make install-repo-path - ~/.config/llm_wiki/repo_path 만 설정"
	@echo "make install-command   - tooling/commands/wiki-log.md 를 ~/.claude/commands/ 로 복사"
	@echo "make uninstall         - 설치된 wiki-log 커맨드와 repo_path 설정 제거"

install: install-repo-path install-command

update: install-command

install-repo-path:
	@mkdir -p $(CONFIG_DIR)
	@echo "$(REPO_PATH)" > $(CONFIG_DIR)/repo_path
	@echo "repo_path 설정: $(CONFIG_DIR)/repo_path -> $(REPO_PATH)"

install-command:
	@mkdir -p $(COMMANDS_DIR)
	@cp tooling/commands/wiki-log.md $(COMMANDS_DIR)/wiki-log.md
	@echo "wiki-log 커맨드 설치: $(COMMANDS_DIR)/wiki-log.md"

uninstall:
	@rm -f $(COMMANDS_DIR)/wiki-log.md
	@rm -f $(CONFIG_DIR)/repo_path
	@echo "wiki-log 커맨드 및 repo_path 설정을 제거했습니다."
