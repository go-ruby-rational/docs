---
title: "Why pure Go"
weight: 20
---

# Why pure Go {#why-pure-go}

`go-ruby-rational/rational` reimplements Ruby's `Rational` in **pure Go, with cgo
disabled**. The number type it covers is **deterministic and interpreter-independent**:
given a numerator and denominator (or a string), every result is a pure function of those
inputs — no live binding, no evaluation of arbitrary Ruby. That is exactly the part that
can — and should — live as a standalone Go library, separate from the interpreter.

## Why a separate, MRI-faithful type {#why-a-separate-mri-faithful-type}

The exact rational core (reduce to lowest terms, exact `+ - * /`, integer `**`) is the
easy part; **matching MRI is in the details**, and those details are why this is a
distinct, MRI-pinned type rather than a generic rational:

- `inspect` prints `(3/4)` while `to_s` prints `3/4` (`String()` returns the inspect
  form);
- rounding is **half-away-from-zero** (`(5/2).round == 3`, `(-5/2).round == -3`);
- the digit-aware `floor`/`ceil`/`round`/`truncate` return a **Rational** for `n >= 1`
  but an **Integer** for `n <= 0`;
- `**` stays exact for an Integer exponent yet falls back to **Float** for a
  Rational/Float exponent.

This is why it is deliberately distinct from
[go-composites/rational](https://github.com/go-composites/rational), which models a
generic mathematical rational rather than Ruby's exact semantics. This package encodes
MRI's rules and pins them with a differential oracle.

## Extracted from rbgo, reusable by anyone {#extracted-from-rbgo-reusable-by-anyone}

It is the `Rational` backend bound into
[go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo`, but is a
**standalone, reusable library** so that:

- any Go program can import `github.com/go-ruby-rational/rational` directly, with no Ruby
  runtime;
- the dependency runs the *other* way — `rbgo` binds this module as a native module (the
  same pattern as [go-ruby-bigdecimal](https://github.com/go-ruby-bigdecimal)), rather
  than this module depending on the interpreter;
- the behaviour is pinned by a **differential oracle** against the system `ruby`,
  independent of any one consumer.

## Why pure Go matters here {#why-pure-go-matters-here}

Because the library is CGO-free and dependency-free (a `math/big.Rat` core only), it:

- cross-compiles to every Go target with no C toolchain, and links into a single static
  binary;
- has **no dependency on the Ruby runtime** — the dependency runs the other way;
- can be differentially tested against the `ruby` binary wherever one is on `PATH`, while
  the cross-arch and Windows lanes (where `ruby` is absent) still validate the library.

{{< callout type="info" >}}
**A note on the libm boundary**

`Pow` with an **integer** exponent is computed exactly. For a **Rational or Float**
exponent MRI returns a `Float` (`a.to_f ** exp`); `PowFloat` provides that fallback
via `math.Pow`. Because Go's `math.Pow` and MRI's C `pow` are independent libm
implementations, a perfect-root case can differ in the last ULP across platforms — the
oracle therefore exercises `Pow` (exact) and only the libm-stable `PowFloat` cases.
{{< /callout >}}

See [Usage & API]({{< relref "api.md" >}}) for the surface and [Roadmap]({{< relref "roadmap.md" >}}) for what is in scope.
