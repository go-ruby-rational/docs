# frozen_string_literal: true
#
# Copyright (c) the go-ruby-rational authors
# SPDX-License-Identifier: BSD-3-Clause
#
# Reference Ruby workload mirroring benchmarks/go/main.go. Rational is a core
# C-extension type in MRI (no require needed). Every operation below runs on the
# SAME inputs as the Go driver, and each op's canonical Rational#to_s is emitted
# as a CHECK line so run.sh can verify byte-identical results before timing.
require_relative "_harness"

# Large, non-trivially-reducible operands so GCD normalisation is real work.
p = Rational(1_234_567_890_123, 9_876_543_210)   # reduces on construction
q = Rational(22, 7)
a = Rational(355, 113)                            # a compact value for to_s
rnum = 12_345_678_901_234_567_890
rden = 9_876_543_210_987_654_321

# --- Verification: canonical to_s of each op's result (checked == Go, == MRI) ---
check("add",          (p + q).to_s)
check("mul",          (p * q).to_s)
check("div",          (p / q).to_s)
check("from-decimal", Rational("3.14159").to_s)  # Rational(String) conversion
check("to_s",         a.to_s)
check("reduce",       Rational(rnum, rden).to_s) # GCD normalisation
check("cmp",          (p <=> q).to_s)

# --- Timed sub-benchmarks (identical inner counts to the Go driver) ---
bench("add",          1000) { p + q }
bench("mul",          1000) { p * q }
bench("div",          1000) { p / q }
bench("from-decimal", 1000) { Rational("3.14159") }
bench("to_s",         1000) { a.to_s }
bench("reduce",       1000) { Rational(rnum, rden) }
bench("cmp",          1000) { p <=> q }
