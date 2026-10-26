include pgxntool/base.mk

# TEST_LOAD_SOURCE selects how pg_temp._create() (test/deps.sql) installs the
# extension:
#   - fresh (default): CREATE EXTENSION at the current version.
#   - update: CREATE EXTENSION at TEST_UPDATE_FROM, then ALTER EXTENSION UPDATE
#     to the current version. The suite and its expected output are the same,
#     so a pass means the updated install behaves like a fresh one.
# The settings reach test/deps.sql as placeholder GUCs via PGOPTIONS, which the
# psql processes pg_regress spawns inherit. They are exported unconditionally so
# deps.sql can read them without missing_ok and fail if they didn't propagate.
TEST_LOAD_SOURCE ?= fresh
ifeq ($(filter $(TEST_LOAD_SOURCE),fresh update),)
$(error TEST_LOAD_SOURCE must be 'fresh' or 'update', got '$(TEST_LOAD_SOURCE)')
endif
TEST_UPDATE_FROM ?= 0.2.0
export PGOPTIONS := $(PGOPTIONS) -c trunklet_format.test_load_mode=$(TEST_LOAD_SOURCE) -c trunklet_format.test_update_from=$(TEST_UPDATE_FROM)

# Recurses rather than depending on `test` so the TEST_LOAD_SOURCE check above
# re-evaluates with update set.
.PHONY: test-update
test-update:
	$(MAKE) test TEST_LOAD_SOURCE=update

# TODO: Remove this after merging pgxntool 0.2.1+
testdeps: $(TEST_SQL_FILES) $(TEST_SOURCE_FILES)

testdeps: $(TESTDIR)/deps.sql $(TESTDIR)/load.sql

#
# OTHER DEPS
#
.PHONY: deps
install: deps
deps: trunklet extension_drop

.PHONY: trunklet
trunklet: $(DESTDIR)$(datadir)/extension/trunklet.control
$(DESTDIR)$(datadir)/extension/trunklet.control:
	pgxn install 'trunklet>=0.3.3' # 0.3.3 adds support for ignore_missing_functions

.PHONY: extension_drop
extension_drop: $(DESTDIR)$(datadir)/extension/extension_drop.control
# 0.1.1 fixes dependencies
$(DESTDIR)$(datadir)/extension/extension_drop.control:
	pgxn install --unstable 'extension_drop>=0.1.1'

