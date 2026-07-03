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
- **Library version:** the numbers below are the pure-Go library **with the int64
  fast path** (a `Rational` whose numerator and denominator both fit `int64` is
  held in machine words; arithmetic runs in `int64` with exact overflow detection
  and promotes to `*big.Rat` only on overflow — MRI's fixnum-num/den strategy). The
  earlier all-`*big.Rat` measurement (add 1.58×, mul 1.83×, div 1.77×,
  from-decimal 2.01×) is superseded; the before→after appears in the table below.

#### add

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 33.2 | 0.32× |
| MRI | 103.0 | 1.00× |
| MRI + YJIT | 81.0 | 0.79× |
| JRuby | 207.1 | 2.01× |
| TruffleRuby | 594.5 | 5.77× |

#### mul

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 42.1 | 0.46× |
| MRI | 92.0 | 1.00× |
| MRI + YJIT | 55.0 | 0.60× |
| JRuby | 241.2 | 2.62× |
| TruffleRuby | 331.1 | 3.60× |

#### div

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 53.1 | 0.54× |
| MRI | 99.0 | 1.00× |
| MRI + YJIT | 61.0 | 0.62× |
| JRuby | 160.1 | 1.62× |
| TruffleRuby | 324.0 | 3.27× |

#### from-decimal

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 25.4 | 0.25× |
| MRI | 102.0 | 1.00× |
| MRI + YJIT | 67.0 | 0.66× |
| JRuby | 781.5 | 7.66× |
| TruffleRuby | 3011.7 | 29.53× |

#### to_s

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 46.3 | 0.46× |
| MRI | 100.0 | 1.00× |
| MRI + YJIT | 72.0 | 0.72× |
| JRuby | 241.4 | 2.41× |
| TruffleRuby | 429.9 | 4.30× |

#### reduce

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 76.8 | 0.28× |
| MRI | 272.0 | 1.00× |
| MRI + YJIT | 253.0 | 0.93× |
| JRuby | 553.9 | 2.04× |
| TruffleRuby | 949.8 | 3.49× |

#### cmp

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 4.3 | 0.11× |
| MRI | 39.0 | 1.00× |
| MRI + YJIT | 25.0 | 0.64× |
| JRuby | 80.8 | 2.07× |
| TruffleRuby | 357.5 | 9.17× |

**Reading the numbers.** With the int64 fast path the pure-Go library is now
**faster than MRI on every operation**, and the small-operand rows that used to
trail have flipped decisively:

| op | before (all-`*big.Rat`) | after (int64 fast path) |
| --- | ---: | ---: |
| add | 1.58× | **0.32×** |
| mul | 1.83× | **0.46×** |
| div | 1.77× | **0.54×** |
| from-decimal | 2.01× | **0.25×** |
| to_s | 0.96× | **0.46×** |
| cmp | 0.93× | **0.11×** |
| reduce | 0.35× | **0.28×** |

`add`/`mul`/`div` now run entirely in machine words (gcd-reduced in `int64`,
overflow-checked with 128-bit `math/bits` products), so they land at **0.3–0.5×
MRI** — roughly **2–3× faster** than MRI's C `Rational` — instead of ~1.6–1.8×
slower. `from-decimal` gained a dedicated int64 decimal parser and drops to
**0.25×** (~4× faster). `cmp` is now an `int64` cross-product comparison — a
handful of nanoseconds, **0.11×**. `to_s` formats the two `int64` fields directly
(no `*big.Rat`), roughly halving its cost to **0.46×**. `reduce` (big coprime
operands that intentionally do **not** fit `int64`) still exercises the
`math/big` GCD path and holds its existing **~3.5× lead** at 0.28×. Exactness is
untouched: any operand or intermediate that exceeds `int64` promotes to the exact
`*big.Rat` path, and the `run.sh` verification confirms every result is
**byte-identical to MRI** (canonical `Rational#to_s`) before timing. MRI + YJIT
still trims MRI's own rows but no longer leads the go column on any operation. The
TruffleRuby columns on the shortest loops remain **cold-JIT outliers** — most
visibly `from-decimal` (29.53×) and `cmp` (9.17×) — where Graal had not compiled
the loop within the warm-up budget; they are not steady-state figures. Every
value is a real measured `ns/op` from the dated run above.

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
