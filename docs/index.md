# go-ruby-rational documentation

**Ruby's `Rational` exact number type in pure Go — MRI byte-exact, no cgo.**

`go-ruby-rational/rational` is a faithful, pure-Go (zero cgo) reimplementation of Ruby's
`Rational` — the exact `numerator/denominator` number type backing literals such as `3r`
and the `Rational()` conversion method — matching reference Ruby (MRI) byte-for-byte. The
module path is `github.com/go-ruby-rational/rational`.

A `Rational` holds an arbitrary-precision ratio in lowest terms with a positive
denominator (Ruby's normalisation: the sign lives on the numerator), and every arithmetic,
comparison and conversion method reproduces MRI's result exactly. It is the `Rational`
backend bound into [go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo`
as a native module — just like [go-ruby-bigdecimal](https://github.com/go-ruby-bigdecimal).
The dependency runs the other way: this library has **no dependency on the Ruby runtime**.

Being **MRI-faithful**, it is deliberately distinct from
[go-composites/rational](https://github.com/go-composites/rational), which models a generic
mathematical rational rather than Ruby's exact semantics.

!!! success "Status: exact number type complete — MRI byte-exact"
    Faithful port of `Rational`: exact `Add`/`Sub`/`Mul`/`Div` (with `ErrZeroDivision`), `Neg`/`Abs`/`Reciprocal`, `Pow` (exact integer exponent) and `PowFloat` (Float fallback), normalisation, the `ToS`/`Inspect` split, conversions and digit-aware rounding (`FloorN`/`CeilN`/`RoundN`/`TruncateN`), comparison against Rational/Integer/Float, `Parse` and `Rationalize`. Validated by a **differential oracle** against the system `ruby` — inspected results compared byte-for-byte — at 100% coverage, `gofmt` + `go vet` clean, CI green across the six 64-bit Go targets and three OSes.

## Why a separate, MRI-faithful type

The exact rational core (reduce to lowest terms, exact `+ - * /`, integer `**`) is the
easy part; **matching MRI is in the details**:

- `inspect` prints `(3/4)` while `to_s` prints `3/4`;
- rounding is **half-away-from-zero** (`(5/2).round == 3`, `(-5/2).round == -3`);
- the digit-aware `floor`/`ceil`/`round`/`truncate` return a **Rational** for `n >= 1`
  but an **Integer** for `n <= 0`;
- `**` stays exact for an Integer exponent yet falls back to **Float** for a
  Rational/Float exponent.

This package encodes those rules and pins them with a differential MRI oracle.

## Quick taste

```go
a, _ := rational.New(big.NewInt(1), big.NewInt(3)) // (1/3)
b, _ := rational.New(big.NewInt(1), big.NewInt(6)) // (1/6)

fmt.Println(a.Add(b).Inspect()) // (1/2)   — Rational#inspect
fmt.Println(a.Add(b).ToS())     // 1/2     — Rational#to_s

r, _ := rational.Parse("10/4")  // Rational("10/4")
fmt.Println(r.Inspect())        // (5/2)
```

## Repositories

| Repo | What it is |
| --- | --- |
| [`rational`](https://github.com/go-ruby-rational/rational) | the library — Ruby's `Rational` exact number type in pure Go |
| [`docs`](https://github.com/go-ruby-rational/docs) | this documentation site (MkDocs Material, versioned with mike) |
| [`go-ruby-rational.github.io`](https://github.com/go-ruby-rational/go-ruby-rational.github.io) | the organization landing page (Hugo) |
| [`brand`](https://github.com/go-ruby-rational/brand) | logo and brand assets |

## Principles

- **Pure Go, `CGO_ENABLED=0`** — trivial cross-compilation, a single static
  binary, no C toolchain.
- **Exact, arbitrary-precision** — a `math/big.Rat` core always reduced to lowest
  terms with a positive denominator; Ruby's exact rational, not floating point.
- **MRI byte-exact.** Output matches reference Ruby exactly, not approximately,
  validated by a differential oracle against the `ruby` binary.
- **Standalone & reusable.** No dependency on the Ruby runtime — the dependency
  runs the other way.
- **100% test coverage** is the target, enforced as a CI gate, across 6 arches
  and 3 OSes.

## Where to go next

- [Why pure Go](why.md) — why this exact number type is deterministic enough to
  live as a standalone, interpreter-independent Go library.
- [Usage & API](api.md) — the public surface and worked examples.
- [Roadmap](roadmap.md) — what is done and what is downstream by design.

Source lives at [github.com/go-ruby-rational/rational](https://github.com/go-ruby-rational/rational).
