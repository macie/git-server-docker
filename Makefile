# This Makefile intended to be POSIX-compliant (2018 edition with .PHONY target).
#
# .PHONY targets are used by task definintions.
#
# More info:
#  - docs: <https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html>
#  - .PHONY: <https://www.austingroupbugs.net/view.php?id=523>
#
.POSIX:
.SUFFIXES:


#
# PUBLIC MACROS
#

LINT    = shellcheck
TEST    = ./unittest


#
# INTERNAL MACROS
#

TEST_SRC=https://github.com/macie/unittest.sh/releases/latest/download/unittest


#
# DEVELOPMENT TASKS
#

.PHONY: all
all: check e2e

.PHONY: clean
clean:
	@echo '# Remove test runner' >&2
	rm -f $(TEST) $(TEST).sha256sum

.PHONY: info
info:
	@printf '# OS info: '
	@uname -rsv;
	@echo '# Development dependencies:'
	@echo; $(LINT) -V || true
	@echo; $(TEST) -v || true
	@echo '# Environment variables:'
	@env || true

.PHONY: check
check: $(LINT)
	@echo '# Static analysis' >&2
	$(LINT) *.sh ./git-shell-commands/*

.PHONY: e2e
e2e: $(TEST)
	@echo '# E2E tests' >&2
	@$(TEST)


#
# DEPENDENCIES
#

$(LINT):
	@printf '# $@ installation path: ' >&2
	@command -v $@ >&2 || { echo "ERROR: Cannot find $@" >&2; exit 1; }

$(TEST):
	@echo '# Prepare $@:' >&2
	curl -fLO $(TEST_SRC)
	curl -fLO $(TEST_SRC).sha256sum
	sha256sum -c $@.sha256sum
 
	chmod +x $@
