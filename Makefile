.PHONY: help check init install install-phpwpinfo backup clean test diagnose-php

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "$(BLUE)WP Adjuvans Starter Kit - Makefile Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup & Installation

check: ## Check system dependencies
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@./cli/check-dependencies.sh

diagnose-php: ## Diagnose PHP installation and environment
	@echo "$(BLUE)Running PHP diagnostic...$(NC)"
	@./cli/diagnose-php.sh

init: check ## Initialize environment (WP-CLI, directories, permissions)
	@echo "$(BLUE)Initializing environment...$(NC)"
	@./cli/init.sh

install: ## Run interactive WordPress installation wizard
	@echo "$(BLUE)Starting interactive installer...$(NC)"
	@./cli/install.sh

install-wordpress: init ## Install WordPress (requires existing config)
	@echo "$(BLUE)Installing WordPress...$(NC)"
	@./cli/install-wordpress.sh

install-phpwpinfo: ## Install phpwpinfo diagnostic tool
	@echo "$(BLUE)Installing phpwpinfo...$(NC)"
	@./cli/install-phpwpinfo.sh

##@ Maintenance

backup: ## Create encrypted backup of WordPress and database
	@echo "$(BLUE)Creating backup...$(NC)"
	@./cli/backup.sh

##@ Development

test: ## Run test suite (if available)
	@echo "$(YELLOW)Test suite coming soon...$(NC)"

lint: ## Check shell scripts for syntax errors
	@echo "$(BLUE)Linting shell scripts...$(NC)"
	@for script in cli/*.sh cli/lib/*.sh; do \
		if [ -f "$$script" ]; then \
			echo "Checking $$script..."; \
			sh -n "$$script" || exit 1; \
		fi \
	done
	@echo "$(GREEN)✓ All scripts have valid syntax$(NC)"

permissions: ## Fix file permissions
	@echo "$(BLUE)Fixing file permissions...$(NC)"
	@chmod +x cli/*.sh cli/lib/*.sh
	@[ -f config/config.sh ] && chmod 600 config/config.sh || true
	@echo "$(GREEN)✓ Permissions fixed$(NC)"

##@ Cleanup

clean: ## Remove WordPress installation (DANGER: deletes everything!)
	@echo "$(RED)WARNING: This will delete WordPress, logs, and backups!$(NC)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)Removing WordPress installation...$(NC)"; \
		rm -rf wordpress/ logs/*.log save/*.tar.gz save/*.gpg; \
		rm -f wp-cli.phar wp-cli.yml wp-completion.bash; \
		echo "$(GREEN)✓ Clean complete$(NC)"; \
	else \
		echo "$(BLUE)Cancelled$(NC)"; \
	fi

clean-logs: ## Remove old log files
	@echo "$(BLUE)Cleaning old logs...$(NC)"
	@find logs/ -name "*.log" -mtime +30 -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Old logs removed$(NC)"

clean-backups: ## Remove old backups (keeps last 7)
	@echo "$(BLUE)Cleaning old backups...$(NC)"
	@find save/ -name "*.tar.gz*" -type f -printf '%T+ %p\n' 2>/dev/null | \
		sort -r | tail -n +8 | cut -d' ' -f2- | xargs rm -f || true
	@echo "$(GREEN)✓ Old backups removed$(NC)"

##@ Information

status: ## Show project status
	@echo "$(BLUE)Project Status:$(NC)"
	@echo ""
	@echo "Configuration:"
	@if [ -f config/config.sh ]; then \
		echo "  $(GREEN)✓$(NC) config/config.sh exists"; \
	else \
		echo "  $(RED)✗$(NC) config/config.sh missing"; \
	fi
	@echo ""
	@echo "WordPress:"
	@if [ -d wordpress ]; then \
		echo "  $(GREEN)✓$(NC) WordPress directory exists"; \
		if [ -f wordpress/wp-config.php ]; then \
			echo "  $(GREEN)✓$(NC) wp-config.php configured"; \
		else \
			echo "  $(YELLOW)!$(NC) wp-config.php missing"; \
		fi; \
	else \
		echo "  $(RED)✗$(NC) WordPress not installed"; \
	fi
	@echo ""
	@echo "WP-CLI:"
	@if [ -f wp-cli.phar ]; then \
		echo "  $(GREEN)✓$(NC) WP-CLI installed"; \
	else \
		echo "  $(RED)✗$(NC) WP-CLI not installed"; \
	fi
	@echo ""
	@echo "Backups:"
	@backup_count=$$(find save/ -name "*.tar.gz*" -type f 2>/dev/null | wc -l | tr -d ' '); \
	if [ $$backup_count -gt 0 ]; then \
		echo "  $(GREEN)✓$(NC) $$backup_count backup(s) found"; \
	else \
		echo "  $(YELLOW)!$(NC) No backups found"; \
	fi

version: ## Show WordPress version (if installed)
	@if [ -f wp-cli.phar ] && [ -d wordpress ]; then \
		cd wordpress && php ../wp-cli.phar core version; \
	else \
		echo "$(YELLOW)WordPress not installed$(NC)"; \
	fi

##@ Advanced

update-wp: ## Update WordPress core
	@if [ -f wp-cli.phar ] && [ -d wordpress ]; then \
		echo "$(BLUE)Updating WordPress...$(NC)"; \
		cd wordpress && php ../wp-cli.phar core update; \
		echo "$(GREEN)✓ WordPress updated$(NC)"; \
	else \
		echo "$(RED)WordPress not installed$(NC)"; \
	fi

update-plugins: ## Update all WordPress plugins
	@if [ -f wp-cli.phar ] && [ -d wordpress ]; then \
		echo "$(BLUE)Updating plugins...$(NC)"; \
		cd wordpress && php ../wp-cli.phar plugin update --all; \
		echo "$(GREEN)✓ Plugins updated$(NC)"; \
	else \
		echo "$(RED)WordPress not installed$(NC)"; \
	fi

update-themes: ## Update all WordPress themes
	@if [ -f wp-cli.phar ] && [ -d wordpress ]; then \
		echo "$(BLUE)Updating themes...$(NC)"; \
		cd wordpress && php ../wp-cli.phar theme update --all; \
		echo "$(GREEN)✓ Themes updated$(NC)"; \
	else \
		echo "$(RED)WordPress not installed$(NC)"; \
	fi

update-all: update-wp update-plugins update-themes ## Update WordPress, plugins, and themes

config-check: ## Validate configuration file syntax
	@if [ -f config/config.sh ]; then \
		echo "$(BLUE)Checking configuration syntax...$(NC)"; \
		sh -n config/config.sh && echo "$(GREEN)✓ Configuration syntax OK$(NC)" || echo "$(RED)✗ Syntax error$(NC)"; \
	else \
		echo "$(YELLOW)Configuration file not found$(NC)"; \
	fi
