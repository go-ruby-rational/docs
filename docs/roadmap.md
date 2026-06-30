# Roadmap

`go-ruby-rational/rational` is grown **test-first**, each capability differential-tested
against MRI rather than built in isolation. Ruby's `Rational` — the exact,
interpreter-independent number type — is **complete**.

| Stage | What | Status |
| --- | --- | --- |
| Exact arithmetic | `Add`/`Sub`/`Mul`/`Div` over arbitrary-precision integers (`math/big.Rat` core), always reduced to lowest terms with a positive denominator; `Div`/0 → `ErrZeroDivision`. `Neg`/`Abs`/`Reciprocal` (0 → `ErrZeroDivision`). | **Done** |
| Pow | Integer exponent stays exact (`(3/4) ** -1 == (4/3)`, `0r ** -1` raises); `PowFloat` for the Rational/Float-exponent Float fallback. | **Done** |
| Normalisation | `Rational(2, 4) → (1/2)`, negative-denominator folding (`Rational(1, -2) → (-1/2)`), `Rational(0, n) → (0/1)`. | **Done** |
| ToS vs Inspect & conversions | MRI's split — `to_s → "3/4"`, `inspect → "(3/4)"`. `ToI` (truncate toward zero), `ToF` (nearest-even), `ToR`, and `Truncate`/`Floor`/`Ceil`/`Round` to an Integer. | **Done** |
| Digit-aware rounding | `FloorN`/`CeilN`/`RoundN`/`TruncateN` return a Rational for `n >= 1` and an Integer for `n <= 0`, with half-away-from-zero rounding. | **Done** |
| Comparison, Parse & oracle | `Cmp`/`Eql`/`EqlStrict` against Rational, Integer and Float (`NaN` → undefined like MRI's `nil`); `Parse` for `Rational(String)`; `Rationalize`. A wide corpus is inspected here and by the system `ruby`, compared byte-for-byte; 100% coverage, gofmt + go vet clean, green across all six 64-bit Go arches and three OSes. | **Done** |

## Documented out-of-scope boundaries

These are **deliberate**, recorded so the module's surface is unambiguous:

- **MRI-faithful, not a generic rational.** This type reproduces Ruby's exact semantics
  byte-for-byte; the generic mathematical rational lives in
  [go-composites/rational](https://github.com/go-composites/rational).
- **`Pow` exactness boundary.** Integer exponents are exact; a Rational/Float exponent
  follows MRI into a `Float` via `PowFloat`, and the oracle only asserts the libm-stable
  `PowFloat` cases (independent libm implementations can differ by a ULP on perfect
  roots).
- **No interpreter.** The library implements the deterministic algorithm; it never runs
  arbitrary Ruby. Anything that needs a live binding is the consumer's job — that is why
  `rbgo` binds this module rather than the reverse.
- **Reference is reference Ruby (MRI).** Byte-for-byte conformance targets MRI's
  behaviour, pinned by the differential oracle.

See [Usage & API](api.md) for the surface and [Why pure Go](why.md) for the
deterministic / interpreter split.
