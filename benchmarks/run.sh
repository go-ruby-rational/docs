#!/usr/bin/env bash
#
# Copyright (c) the go-ruby-rational authors
# SPDX-License-Identifier: BSD-3-Clause
#
# Library-level cross-runtime benchmark runner for go-ruby-rational.
#
# Runs the SAME workload through (a) the pure-Go go-ruby-rational library
# (benchmarks/go, pinned by go.mod to the published pseudo-version) and (b) each
# available reference Ruby runtime (benchmarks/ruby/rational.rb). It FIRST
# verifies that the Go driver's canonical Rational#to_s outputs are byte-identical
# to MRI's (CHECK lines) and aborts on any mismatch, THEN prints one Markdown
# table per sub-benchmark: ns/op and the ratio vs MRI.
#
# Usage:  bash benchmarks/run.sh
# Env:    OUTER (timed passes, default 25), WARM (untimed passes, default 3),
#         RUBY / JRUBY / TRUFFLERUBY (override runtime binaries).
set -u
cd "$(dirname "$0")"

RUBY=${RUBY:-ruby}
JRUBY=${JRUBY:-jruby}
TRUFFLERUBY=${TRUFFLERUBY:-truffleruby}

RB=ruby/rational.rb
export GOWORK=off
export GOFLAGS=-mod=mod

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- Capture full output (CHECK + RESULT) from Go and MRI ---------------------
echo "== go-ruby-rational library-level benchmark ==" >&2
echo "  go (pure-Go library) ..." >&2
( cd go && go run . ) > "$WORK/go.out" 2> "$WORK/go.err" || {
  echo "ERROR: Go driver failed:" >&2; cat "$WORK/go.err" >&2; exit 1; }

echo "  mri (oracle) ..." >&2
"$RUBY" "$RB" > "$WORK/mri.out" 2> "$WORK/mri.err" || {
  echo "ERROR: MRI failed:" >&2; cat "$WORK/mri.err" >&2; exit 1; }

# --- Verify Go outputs == MRI outputs (canonical to_s) BEFORE timing ----------
grep '^CHECK' "$WORK/go.out"  | sort > "$WORK/go.chk"
grep '^CHECK' "$WORK/mri.out" | sort > "$WORK/mri.chk"
if ! diff -u "$WORK/mri.chk" "$WORK/go.chk" >&2; then
  echo "ERROR: Go output differs from MRI — refusing to time mismatched results." >&2
  exit 1
fi
echo "  verification: Go output == MRI output (canonical Rational#to_s) OK" >&2

TMP="$WORK/results.tsv"
grep '^RESULT' "$WORK/go.out"  | awk '{printf "go\t%s\t%s\n",  $2, $3}' >> "$TMP"
grep '^RESULT' "$WORK/mri.out" | awk '{printf "mri\t%s\t%s\n", $2, $3}' >> "$TMP"

run() { # <runtime-label> <cmd...>
  local label=$1; shift
  command -v "$1" >/dev/null 2>&1 || { echo "  ($label: $1 not found — skipped)" >&2; return; }
  echo "  $label ..." >&2
  "$@" "$RB" 2>/dev/null | awk -v r="$label" '$1=="RESULT"{printf "%s\t%s\t%s\n", r, $2, $3}' >> "$TMP"
}
run "mri-yjit"    "$RUBY" --yjit
run "jruby"       "$JRUBY"
run "truffleruby" "$TRUFFLERUBY"

echo >&2
# Emit one Markdown table per sub-benchmark (label), runtimes as rows.
awk -F'\t' '
  { key=$2; rt=$1; ns=$3; labels[key]=1; val[rt SUBSEP key]=ns; rts[rt]=1 }
  END {
    order="go mri mri-yjit jruby truffleruby"
    n=split(order, ord, " ")
    # Fixed, meaningful op order.
    split("add mul div from-decimal to_s reduce cmp", lab, " ")
    for (i=1;i<=7;i++){
      k=lab[i]
      if (!(k in labels)) continue
      printf "\n#### %s\n\n", k
      print  "| Runtime | ns/op | vs MRI |"
      print  "| --- | ---: | ---: |"
      base=val["mri" SUBSEP k]
      for (o=1;o<=n;o++){
        rt=ord[o]; v=val[rt SUBSEP k]
        if (v=="") continue
        ratio=(base!=""&&base+0>0)? sprintf("%.2f×", v/base) : "—"
        name=rt
        if (rt=="go") name="**go-ruby (pure Go)**"
        else if (rt=="mri") name="MRI"
        else if (rt=="mri-yjit") name="MRI + YJIT"
        else if (rt=="jruby") name="JRuby"
        else if (rt=="truffleruby") name="TruffleRuby"
        printf "| %s | %s | %s |\n", name, v, ratio
      }
    }
  }
' "$TMP"
