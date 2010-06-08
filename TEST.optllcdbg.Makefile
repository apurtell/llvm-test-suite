##===- TEST.optllcdbg.Makefile -----------------------------*- Makefile -*-===##
#
# This test checks whether presence of debug declarations influences
# the code generator or not. 
#
# If input.bc includes llvm.dbg intrinsics and llvm.dbg variables then
# the code in first.s and second.s should match. Otherwise debugging information
# is influencing the code generator.  The Dwarf info in first.s and second.s is
# normally quite different, so the data directives that appear in Dwarf are
# stripped out before comparison.
#
# This has only been used on Darwin; the data directives to strip and grep magic
# might be different elsewhere.
#
##===----------------------------------------------------------------------===##

TESTNAME = $*
TEST_TARGET_FLAGS = -g -O0
LLC_DEBUG_FLAGS = -O3 $(LLCFLAGS)
OPT_FLAGS = -std-compile-opts
.PRECIOUS: Output/%.first.s Output/%.second.s Output/%.t2c.s Output/%.t1c.s Output/%.t2b.bc Output/%.t1b.bc Output/%.t1a.bc Output/%.t2a.bc

$(PROGRAMS_TO_TEST:%=test.$(TEST).%): \
test.$(TEST).%: Output/%.diff

Output/%.t1a.bc: Output/%.linked.rbc Output/.dir $(LOPT)
	$(LOPT) -strip-debug-declare -strip-nondebug $< -f -o $@

Output/%.t1b.bc: Output/%.t1a.bc Output/.dir $(LOPT)
	$(LOPT) $(OPT_FLAGS) $< -f -o $@

Output/%.t1c.s: Output/%.t1b.bc Output/.dir $(LLC)
	$(LLC) $(LLC_DEBUG_FLAGS) $< -o $@

Output/%.first.s: Output/%.t1c.s Output/.dir $(LLC)
	grep -v '\.long' < $< | grep -v '\.byte' | grep -v '\.short' | grep -v '\.asci' | grep -v '\.quad' | grep -v '## DW_AT' | grep -v '## Abbrev' | grep -v '## End Of Children' | grep -v '## Extended Op' | grep -v 'Ltmp[0-9]' | grep -v '## DIE' | grep -v '## $$' | grep -v '^#.*' | grep -v '^$$' | grep -v '__debug_str' | grep -v 'Lstring' | grep -v 'Lset' | grep -v 'debug_loc' | grep -v 'Lpubtypes' | grep -v 'Lpubnames' | grep -v 'Linfo_' > $@

Output/%.t2a.bc: Output/%.linked.rbc Output/.dir $(LOPT)
	$(LOPT) -strip-nondebug $< -f -o $@

Output/%.t2b.bc: Output/%.t2a.bc Output/.dir $(LOPT)
	$(LOPT) $(OPT_FLAGS) $< -f -o $@

Output/%.t2c.s: Output/%.t2b.bc Output/.dir $(LLC)
	$(LLC) $(LLC_DEBUG_FLAGS) $< -o $@

Output/%.second.s: Output/%.t2c.s Output/.dir
	grep -v DEBUG_VALUE < $< | grep -v '\.long' | grep -v '\.byte' | grep -v '\.short' | grep -v '\.asci' | grep -v '## DW_AT' | grep -v '## Abbrev' |  grep -v '## End Of Children' | grep -v '## Extended Op' | grep -v 'Ltmp[0-9]' | grep -v '## DIE' | grep -v '## $$' | grep -v '\.quad' | grep -v '^#' | grep -v '^$$' | grep -v '__debug_str' | grep -v 'Lstring' | grep -v 'Lset' | grep -v 'debug_loc' | grep -v 'Lpubtypes' | grep -v 'Lpubnames' | grep -v 'Linfo_' > $@

Output/%.diff: Output/%.first.s Output/%.second.s
	@-if diff $^ > $@; then \
	 echo "--------- TEST-PASS: $*"; \
	else \
	 echo "--------- TEST-FAIL: $*"; \
	fi
