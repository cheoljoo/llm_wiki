CONFIG_DIR  := $(HOME)/.config/llm_wiki
COMMANDS_DIR := $(HOME)/.claude/commands
# VS Code user prompt files 위치 (Linux/macOS 공통 경로; 필요 시 재정의)
COPILOT_PROMPTS_DIR := $(HOME)/.config/llm_wiki/copilot-prompts
REPO_PATH   := $(CURDIR)

# 어느 프로젝트에서든 호출해야 하는 user-level 커맨드들 (wiki-digest는 이 저장소 안에서만 쓰므로 제외)
USER_COMMANDS := wiki-log wiki-recall wiki-report wiki-todo

# VS Code user settings.json 경로 (Linux 기본값)
VSCODE_SETTINGS := $(HOME)/.config/Code/User/settings.json

.DEFAULT_GOAL := help

.PHONY: help install install-repo-path install-command install-copilot \
        update update-copilot uninstall

help:
	@echo "=== Claude Code ==="
	@echo "make install           - repo_path 설정 + wiki-* Claude 커맨드 설치 (최초 1회)"
	@echo "                         ($(USER_COMMANDS))"
	@echo "make update            - wiki-* Claude 커맨드만 다시 복사 (git pull 후)"
	@echo "make install-repo-path - ~/.config/llm_wiki/repo_path 만 설정"
	@echo "make install-command   - tooling/commands/wiki-*.md 를 ~/.claude/commands/ 로 복사"
	@echo ""
	@echo "=== GitHub Copilot ==="
	@echo "make install-copilot   - repo_path 설정 + wiki-log Copilot 프롬프트 설치"
	@echo "                         (VS Code 설정에 chat.promptFilesLocations 추가 방법도 안내)"
	@echo "make update-copilot    - wiki-log Copilot 프롬프트만 다시 복사 (git pull 후)"
	@echo "                         (wiki-digest 는 .github/prompts/ 에 이미 있으므로 별도 설치 불필요)"
	@echo ""
	@echo "=== 제거 ==="
	@echo "make uninstall         - 설치된 wiki-* 커맨드와 repo_path 설정 제거"

# ── Claude Code ──────────────────────────────────────────────────────────────

all: install install-copilot

install: install-repo-path install-command

update: install-command

install-repo-path:
	@mkdir -p $(CONFIG_DIR)
	@echo "$(REPO_PATH)" > $(CONFIG_DIR)/repo_path
	@echo "repo_path 설정: $(CONFIG_DIR)/repo_path -> $(REPO_PATH)"

install-command:
	@mkdir -p $(COMMANDS_DIR)
	@for cmd in $(USER_COMMANDS); do \
		cp tooling/commands/$$cmd.md $(COMMANDS_DIR)/$$cmd.md; \
		echo "$$cmd Claude 커맨드 설치: $(COMMANDS_DIR)/$$cmd.md"; \
	done

# ── GitHub Copilot ───────────────────────────────────────────────────────────

install-copilot: install-repo-path _install-copilot-prompt _print-copilot-vscode-hint

update-copilot: _install-copilot-prompt

_install-copilot-prompt:
	@mkdir -p $(COPILOT_PROMPTS_DIR)
	@cp tooling/copilot-prompts/wiki-log.prompt.md $(COPILOT_PROMPTS_DIR)/wiki-log.prompt.md
	@echo "wiki-log Copilot 프롬프트 설치: $(COPILOT_PROMPTS_DIR)/wiki-log.prompt.md"

_print-copilot-vscode-hint:
	@echo ""
	@echo "──────────────────────────────────────────────────────────────────"
	@echo "VS Code 설정에 아래 항목을 추가하면 모든 프로젝트에서 wiki-log 를"
	@echo "Copilot 채팅 파일 첨부(#wiki-log)로 호출할 수 있습니다."
	@echo ""
	@echo "  설정 파일: $(VSCODE_SETTINGS)"
	@echo ""
	@echo '  "chat.promptFilesLocations": {'
	@echo '    "$${userHome}/.config/llm_wiki/copilot-prompts": true'
	@echo '  }'
	@echo ""
	@echo "이미 chat.promptFilesLocations 가 있다면 해당 키 안에 한 줄만 추가하세요."
	@echo "──────────────────────────────────────────────────────────────────"

# ── 제거 ──────────────────────────────────────────────────────────────────────

uninstall:
	@for cmd in $(USER_COMMANDS); do rm -f $(COMMANDS_DIR)/$$cmd.md; done
	@rm -f $(COPILOT_PROMPTS_DIR)/wiki-log.prompt.md
	@rm -f $(CONFIG_DIR)/repo_path
	@echo "wiki-* 커맨드($(USER_COMMANDS)) 및 repo_path 설정을 제거했습니다."
