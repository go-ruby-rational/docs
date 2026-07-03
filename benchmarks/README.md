<!-- SPDX-License-Identifier: BSD-3-Clause -->
# `go-ruby-rational` library-level benchmark harness

Reproducible, cross-runtime benchmark of the **pure-Go `go-ruby-rational`
library** against the reference Ruby runtimes (MRI, MRI + YJIT, JRuby,
TruffleRuby). It measures the **library primitive** through its Go API, isolated
from the `rbgo` interpreter, so the numbers answer: *is the pure-Go
implementation as fast as the reference runtime's own `Rational`?*

## Layout

- `go/`             — self-contained Go driver; `go.mod` pins the **published**
  library by pseudo-version (resolved via the Go module proxy, no `replace`).
- `ruby/rational.rb` — the equivalent workload; `ruby/_harness.rb` is the shared
  timer.
- `run.sh`          — verifies Go output == MRI output, then runs every available
  runtime and prints one Markdown table per sub-benchmark (ns/op + ratio vs MRI).

## Run

```sh
bash benchmarks/run.sh
```

Environment knobs: `OUTER` (timed passes, default 25), `WARM` (untimed warm-up
passes, default 3), and `RUBY`/`JRUBY`/`TRUFFLERUBY` to select runtime binaries.

## Operations

Exact `Rational` arithmetic and conversions, on identical large operands:
`add`, `mul`, `div`, `from-decimal` (`Rational(String)` conversion), `to_s`,
`reduce` (GCD normalisation on construction) and `cmp` (`<=>`).

## Method

Each process runs `WARM` untimed passes (to let the JVM/GraalVM JITs warm up),
then `OUTER` timed passes of a fixed inner loop, timed with a monotonic clock;
the **best** pass is reported as **ns/op**. Interpreter start-up is outside the
timed region. The Go driver and the Ruby script build **identical inputs**, and
each op's canonical `Rational#to_s` is emitted as a `CHECK` line and diffed —
`run.sh` aborts if any Go result differs from MRI **before** timing. Results are
published, dated, in [`../docs/performance.md`](../docs/performance.md).

The built `go/bench` binary is git-ignored — only source is committed.
