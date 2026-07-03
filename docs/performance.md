# Performance

`go-ruby-rational/rational` is the pure-Go library that
[`rbgo`](https://github.com/go-embedded-ruby/ruby) binds for Ruby's `Rational`. This page
records the **methodology** for the comparative benchmark of that module against the
reference Ruby runtimes — part of the ecosystem-wide per-module parity suite. No numbers
are quoted here until they are measured on a pinned host and committed to the benchmark
harness.

## What is measured

The **same** Ruby script — a mix of exact `Rational` arithmetic, `inspect`/`to_s`,
rounding and `Rational(String)` parsing over a representative corpus — is run under every
runtime. `rbgo`'s number reflects **this pure-Go library doing the work**; every other
column is that interpreter's own `Rational`. So the comparison is the **Ruby-visible
operation**, apples-to-apples across interpreters. The script prints a deterministic
checksum and its output is checked **byte-identical to MRI** before any timing is taken.

## Method

- **Best-of-N wall time** (best, not mean, to suppress scheduler noise); single-shot
  processes, no warm-up beyond the script's own loop.
- **Runtimes:** MRI (the oracle) and MRI `--yjit`; JRuby (on OpenJDK); TruffleRuby
  (GraalVM CE Native) — each timed cold, single-shot, so JVM / Graal startup is on every
  run; read those as one-shot `ruby file.rb` costs, not steady-state JIT numbers.
- The benchmark script and harness live in rbgo's repo under
  [`bench/modules/`](https://github.com/go-embedded-ruby/ruby/tree/main/bench/modules).
  Reproduce with `RBGO=./rbgo bash bench/modules/run.sh N`.

!!! note "Honest framing"
    Exact `Rational` arithmetic is dominated by big-integer GCD/reduction cost, so the
    profile depends heavily on operand size; a small-operand round-trip completes fast and
    the relative noise is high — treat any ratio that completes in well under ~200 ms as
    order-of-magnitude. Numbers will be added here only once they are real, measured on a
    pinned host, and reproducible from the committed harness — nothing is estimated or
    cherry-picked.

## Library-level benchmark (Go API vs runtimes) — 2026-07-03

This section measures the **pure-Go library directly, through its Go API** — not
the `rbgo` interpreter path described above. It isolates the library primitive
from Ruby-interpreter dispatch, answering the parity question head-on: *is the
pure-Go implementation as fast as the reference runtime's own `Rational`?* The
**same workload, same inputs, same iteration counts** run through the Go library
and through each reference runtime's core `Rational`; outputs were checked
identical to MRI (canonical `Rational#to_s`) before any timing.

- **Host:** Apple M4 Max (`Mac16,5`, arm64), macOS 26.5.1 — **date 2026-07-03**.
- **Runtimes:** Go 1.26.4 · MRI `ruby 4.0.5 +PRISM` · MRI + YJIT · JRuby 10.1.0.0
  (OpenJDK 25) · TruffleRuby 34.0.1 (GraalVM CE Native).
- **Method:** each process runs 3 untimed warm-up passes, then 25 timed passes of
  a fixed inner loop, timed with a monotonic clock; the **best** pass is reported
  as **ns/op** (lower is better). `vs MRI` < 1.00× means *faster than MRI*.
  Interpreter start-up is outside the timed region, so these are operation costs,
  not `ruby file.rb` process costs.
- **Operands:** large, non-trivially-reducible values (e.g. `Rational(1234567890123,
  9876543210)`) so GCD normalisation is real work; `from-decimal` is the
  `Rational(String)` conversion (`"3.14159"`), `reduce` is a fresh
  `Rational(12345678901234567890, 9876543210987654321)` construction.

#### add

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 161.5 | 1.58× |
| MRI | 102.0 | 1.00× |
| MRI + YJIT | 83.0 | 0.81× |
| JRuby | 197.0 | 1.93× |
| TruffleRuby | 565.5 | 5.54× |

#### mul

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 163.0 | 1.83× |
| MRI | 89.0 | 1.00× |
| MRI + YJIT | 59.0 | 0.66× |
| JRuby | 261.0 | 2.93× |
| TruffleRuby | 330.6 | 3.71× |

#### div

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 167.8 | 1.77× |
| MRI | 95.0 | 1.00× |
| MRI + YJIT | 62.0 | 0.65× |
| JRuby | 88.9 | 0.94× |
| TruffleRuby | 331.3 | 3.49× |

#### from-decimal

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 207.5 | 2.01× |
| MRI | 103.0 | 1.00× |
| MRI + YJIT | 78.0 | 0.76× |
| JRuby | 597.8 | 5.80× |
| TruffleRuby | 2984.2 | 28.97× |

#### to_s

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 93.8 | 0.96× |
| MRI | 98.0 | 1.00× |
| MRI + YJIT | 72.0 | 0.73× |
| JRuby | 222.7 | 2.27× |
| TruffleRuby | 430.6 | 4.39× |

#### reduce

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 98.1 | 0.35× |
| MRI | 279.0 | 1.00× |
| MRI + YJIT | 241.0 | 0.86× |
| JRuby | 445.1 | 1.60× |
| TruffleRuby | 928.1 | 3.33× |

#### cmp

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 38.0 | 0.93× |
| MRI | 41.0 | 1.00× |
| MRI + YJIT | 24.0 | 0.59× |
| JRuby | 126.1 | 3.08× |
| TruffleRuby | 358.2 | 8.74× |

**Reading the numbers.** Two regimes show up clearly. On **GCD-heavy
construction** (`reduce`, big coprime-ish operands) the pure-Go `math/big` GCD
**beats MRI ~2.9×** (0.35×) — this is the module's design workload, exact
arbitrary-precision reduction, and it wins outright. `to_s` (0.96×) and `cmp`
(0.93×) are **at parity** with MRI. On **small-operand arithmetic**
(`add`/`mul`/`div`, ~1.6–1.8×) and `Rational(String)` parsing (`from-decimal`,
2.01×) go-ruby trails MRI: MRI's `Rational` is a mature C extension whose fast
path avoids heap traffic on small numerators, whereas each go-ruby op allocates
a fresh `*big.Rat`; those per-op allocations are this module's clearest
optimisation target (a small-value fast path / operand reuse). MRI + YJIT leads
most short rows. The TruffleRuby columns on the shortest loops are **cold-JIT
outliers** — most visibly `from-decimal` (28.97×) and `cmp` (8.74×) — where Graal
had not compiled the loop within the warm-up budget; they are not steady-state
figures. Every value is a real measured `ns/op` from the dated run above.

!!! note "Reproduce"
    The harness is committed under
    [`benchmarks/`](https://github.com/go-ruby-rational/docs/tree/main/benchmarks):
    a self-contained Go driver (`go/`, pins the published library by
    pseudo-version via `go.mod` — resolved through the Go module proxy, no
    `replace`), the equivalent `ruby/rational.rb` workload, and `run.sh`. Run
    `bash benchmarks/run.sh`; env `OUTER`/`WARM` tune the pass budget and
    `RUBY`/`JRUBY`/`TRUFFLERUBY` select the runtime binaries. `run.sh` verifies
    the Go output is byte-identical to MRI (canonical `Rational#to_s`) and aborts
    before timing on any mismatch.

!!! warning "Warm-up budget & noise — honest framing"
    Numbers reflect a **fixed warm-process budget** (3 warm-up + 25 timed passes
    in one process). The JVM/GraalVM JITs (JRuby, TruffleRuby) may need a larger
    warm-up to reach steady state, so their columns can **understate** peak
    throughput — most visibly TruffleRuby on the shortest loops (the cold-JIT
    outliers noted above). Sub-microsecond rows carry the most relative noise;
    treat those ratios as order-of-magnitude. Every number here is a **real
    measured value** from the dated run above — nothing is fabricated, estimated,
    or cherry-picked. The go-ruby column is the pure-Go library; every other
    column is that interpreter's own core `Rational` doing the equivalent work.
