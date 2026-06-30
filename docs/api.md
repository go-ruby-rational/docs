# Usage & API

The public API lives at the module root (`github.com/go-ruby-rational/rational`). It is
**Ruby-shaped but Go-idiomatic**: the methods mirror Ruby's `Rational` (`+`, `to_s`,
`inspect`, `round`, …), while the surface follows Go conventions — value types built on
`math/big`, an explicit `error` where Ruby raises, no global state.

!!! success "Status: implemented"
    The library is built and importable as `github.com/go-ruby-rational/rational`, bound into `rbgo` as a native module; see [Roadmap](roadmap.md).

## Install

```sh
go get github.com/go-ruby-rational/rational
```

## Worked example

```go
package main

import (
	"fmt"
	"math/big"

	"github.com/go-ruby-rational/rational"
)

func main() {
	a, _ := rational.New(big.NewInt(1), big.NewInt(3)) // (1/3)
	b, _ := rational.New(big.NewInt(1), big.NewInt(6)) // (1/6)

	fmt.Println(a.Add(b).Inspect()) // (1/2)      — Rational#inspect
	fmt.Println(a.Add(b).ToS())     // 1/2        — Rational#to_s

	r, _ := rational.Parse("10/4")  // Rational("10/4")
	fmt.Println(r.Inspect())        // (5/2)

	p, _ := r.Pow(big.NewInt(-1))   // (5/2) ** -1
	fmt.Println(p.Inspect())        // (2/5)

	fmt.Println(rational.FromInt64(5).
		Mul(r).Inspect())           // (25/2)

	// Digit-aware rounding mirrors MRI: n >= 1 → Rational, n <= 0 → Integer.
	q, _, _ := r.Mul(a).RoundN(2)   // (5/6).round(2)
	fmt.Println(q.Inspect())        // (83/100)
}
```

## Shape

```go
// Construction
func New(num, den *big.Int) (*Rational, error) // Rational(num, den); den==0 → ErrZeroDivision
func FromInt(n *big.Int) *Rational              // Rational(n)
func FromInt64(n int64) *Rational
func Parse(s string) (*Rational, error)         // Rational(String)

// Arithmetic
func (a *Rational) Add(b *Rational) *Rational
func (a *Rational) Sub(b *Rational) *Rational
func (a *Rational) Mul(b *Rational) *Rational
func (a *Rational) Div(b *Rational) (*Rational, error) // /0 → ErrZeroDivision
func (a *Rational) Neg() *Rational
func (a *Rational) Abs() *Rational
func (a *Rational) Reciprocal() (*Rational, error)      // 1/a; 1/0 → ErrZeroDivision
func (a *Rational) Pow(exp *big.Int) (*Rational, error) // exact; 0**(-n) → ErrZeroDivision
func (a *Rational) PowFloat(exp float64) float64        // Float fallback (a.to_f ** exp)

// Components
func (a *Rational) Numerator() *big.Int   // sign lives here
func (a *Rational) Denominator() *big.Int // always positive

// Conversion & rounding
func (a *Rational) ToI() *big.Int   // truncate toward zero
func (a *Rational) ToF() float64
func (a *Rational) ToR() *Rational
func (a *Rational) Truncate() *big.Int
func (a *Rational) Floor() *big.Int
func (a *Rational) Ceil() *big.Int
func (a *Rational) Round() *big.Int // half away from zero
func (a *Rational) FloorN(n int) (rat *Rational, i *big.Int, isRat bool)    // n>=1 → Rational
func (a *Rational) CeilN(n int) (rat *Rational, i *big.Int, isRat bool)
func (a *Rational) RoundN(n int) (rat *Rational, i *big.Int, isRat bool)
func (a *Rational) TruncateN(n int) (rat *Rational, i *big.Int, isRat bool)
func (a *Rational) Rationalize() *Rational

// Comparison
func (a *Rational) Cmp(b *Rational) int             // <=>
func (a *Rational) CmpInt(n *big.Int) int
func (a *Rational) CmpFloat(f float64) (c int, ok bool) // ok=false for NaN (MRI nil)
func (a *Rational) Eql(b *Rational) bool            // ==
func (a *Rational) EqlInt(n *big.Int) bool          // (3/1) == 3
func (a *Rational) EqlFloat(f float64) bool         // (1/2) == 0.5
func (a *Rational) EqlStrict(b *Rational) bool      // eql? — Rational only

// Rendering
func (a *Rational) ToS() string     // "3/4"
func (a *Rational) Inspect() string // "(3/4)"
func (a *Rational) String() string  // inspect form (fmt.Stringer)

var ErrZeroDivision    error // ZeroDivisionError ("divided by 0")
var ErrInvalidArgument error // ArgumentError (unparseable Rational string)
```

## MRI conformance

Correctness is defined by reference Ruby. A **differential oracle** runs a wide corpus
through both the system `ruby` and this library and compares the inspected results
**byte-for-byte** — not approximated from memory. The oracle gates on
`RUBY_VERSION >= "4.0"` and binmodes stdout/stdin so Windows text-mode never pollutes the
bytes; it skips itself where `ruby` is not on `PATH` (the qemu arch lanes), so the
cross-arch builds still validate the library.

## Notes on MRI fidelity

`Pow` with an **integer** exponent is computed exactly. For a **Rational or Float**
exponent MRI returns a `Float` (`a.to_f ** exp`); `PowFloat` provides that fallback via
`math.Pow`. Because Go's `math.Pow` and MRI's C `pow` are independent libm
implementations, a perfect-root case (e.g. `8.0 ** (1.0/3.0)`) can differ in the last ULP
across platforms — the oracle therefore exercises `Pow` (exact) and only the libm-stable
`PowFloat` cases.

## Relationship to Ruby

`go-ruby-rational/rational` is **standalone and reusable**, and is the `Rational` backend
bound into [go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo` as a
native module — the same way [go-ruby-bigdecimal](https://github.com/go-ruby-bigdecimal)
is bound. The dependency runs the other way: this library has no dependency on the Ruby
runtime.
