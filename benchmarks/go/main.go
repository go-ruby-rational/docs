// Copyright (c) the go-ruby-rational authors
// SPDX-License-Identifier: BSD-3-Clause
//
// Go driver for the go-ruby-rational library-level benchmark. It exercises the
// pure-Go rational.Rational primitive through its public Go API on the SAME
// inputs as ruby/rational.rb, emitting CHECK lines (canonical to_s of every op
// result, for cross-runtime verification) and RESULT lines (ns/op).
package main

import (
	"fmt"
	"math/big"

	"github.com/go-ruby-rational/rational"
)

func bigOf(s string) *big.Int {
	n, ok := new(big.Int).SetString(s, 10)
	if !ok {
		panic("bad int: " + s)
	}
	return n
}

func newOf(num, den string) *rational.Rational {
	r, err := rational.New(bigOf(num), bigOf(den))
	if err != nil {
		panic(err)
	}
	return r
}

func main() {
	// Same operands as ruby/rational.rb.
	p := newOf("1234567890123", "9876543210") // reduces on construction
	q := newOf("22", "7")
	a := newOf("355", "113")
	rnum := bigOf("12345678901234567890")
	rden := bigOf("9876543210987654321")

	mustDiv := func(x, y *rational.Rational) *rational.Rational {
		v, err := x.Div(y)
		if err != nil {
			panic(err)
		}
		return v
	}
	mustParse := func(s string) *rational.Rational {
		v, err := rational.Parse(s)
		if err != nil {
			panic(err)
		}
		return v
	}
	mustNew := func(n, d *big.Int) *rational.Rational {
		v, err := rational.New(n, d)
		if err != nil {
			panic(err)
		}
		return v
	}

	// --- Verification: canonical ToS of each op's result (checked == MRI) ---
	check("add", p.Add(q).ToS())
	check("mul", p.Mul(q).ToS())
	check("div", mustDiv(p, q).ToS())
	check("from-decimal", mustParse("3.14159").ToS())
	check("to_s", a.ToS())
	check("reduce", mustNew(rnum, rden).ToS())
	check("cmp", fmt.Sprintf("%d", p.Cmp(q)))

	// --- Timed sub-benchmarks (identical inner counts to the Ruby workload) ---
	bench("add", 1000, func() { sink = p.Add(q) })
	bench("mul", 1000, func() { sink = p.Mul(q) })
	bench("div", 1000, func() { sink = mustDiv(p, q) })
	bench("from-decimal", 1000, func() { sink = mustParse("3.14159") })
	bench("to_s", 1000, func() { sink = a.ToS() })
	bench("reduce", 1000, func() { sink = mustNew(rnum, rden) })
	bench("cmp", 1000, func() { sink = p.Cmp(q) })
}
