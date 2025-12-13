from __future__ import annotations

import argparse
import concurrent.futures
import functools
import math
import os.path
import string
import sys
from typing import NamedTuple
from typing import Self

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


class Term(NamedTuple):
    var: str
    k: int

    def __repr__(self) -> str:
        if self.k != 1:
            return f'{self.k} * {self.var}'
        else:
            return self.var


class Equation(NamedTuple):
    terms: frozenset[Term]
    const: int

    @property
    def illegal(self) -> bool:
        return (
            self.const < 0 or
            (self.const and not self.terms) or
            (
                len(self.terms) == 1 and
                self.const % next(iter(self.terms)).k != 0
            )
        )

    @classmethod
    def make(cls, terms: frozenset[Term], const: int) -> Self:
        assert all(term.k > 0 for term in terms), terms
        gcd = math.gcd(const, *(term.k for term in terms))
        if gcd == 0 or gcd == 1:
            return cls(terms, const)
        else:
            terms = frozenset(Term(var, k // gcd) for var, k in terms)
            return cls(terms, const // gcd)

    def subtract(self, other: Equation) -> Equation | None:
        if self.terms > other.terms:
            terms = self.terms - other.terms
            return type(self).make(terms, self.const - other.const)

        elif all(term.k == 1 for term in other.terms):
            s_terms = {term.var: term.k for term in self.terms}
            other_vars = {term.var for term in other.terms}
            if s_terms.keys() > other_vars:
                n = min(v for k, v in s_terms.items() if k in other_vars)
                for k in other_vars:
                    s_terms[k] -= n
                terms = frozenset(
                    Term(var, k)
                    for var, k in s_terms.items()
                    if k
                )
                return type(self).make(terms, self.const - other.const * n)
            else:
                return None
        else:
            return None

    def solve(self) -> tuple[str, int]:
        term, = self.terms
        assert self.const % term.k == 0, self
        return term.var, self.const // term.k

    def substitute(self, var: str, n: int) -> Self:
        if not any(t.var == var for t in self.terms):
            return self
        removed, = (term for term in self.terms if term.var == var)
        terms = frozenset(term for term in self.terms if term.var != var)
        # assert terms or self.const == n, self
        # if not terms:
        #     breakpoint()
        return type(self).make(terms, self.const - removed.k * n)

    def __repr__(self) -> str:
        lhs = ' + '.join(repr(term) for term in sorted(self.terms))
        return f'<{type(self).__name__} {lhs} = {self.const}>'


_TRIVIAL_EQUATION = Equation(frozenset(), 0)


System = frozenset[Equation]


def _substitute(system: System, var: str, n: int) -> System:
    return _simplify(frozenset(eq.substitute(var, n) for eq in system))


def _simplify(system: System) -> System:
    if any(eq.illegal for eq in system):
        return system
    elif _TRIVIAL_EQUATION in system:
        return _simplify(system - {_TRIVIAL_EQUATION})

    for equation in system:
        if equation.const == 0:
            for term in equation.terms:
                system = _substitute(system, term.var, 0)
            return _simplify(system)

    for equation in system:
        for other in system:
            if equation is other:
                continue

            new_eq = equation.subtract(other)
            if new_eq is not None:
                return _simplify((system - {equation}) | {new_eq})
    return system


def _solve_var(system: System) -> tuple[int | None, System]:
    for equation in system:
        if len(equation.terms) == 1:
            var, n = equation.solve()
            return n, _simplify(_substitute(system, var, n))
    else:
        return None, _simplify(system)


def _pick_var(system: System) -> tuple[str, int]:
    # TODO: optimize? rarest? shortest equation?
    var = min(term.var for eq in system for term in eq.terms)
    high = sys.maxsize
    for eq in system:
        matching = next((t for t in eq.terms if t.var == var), None)
        if matching is not None:
            high = min(high, eq.const // matching.k)
    return var, high


@functools.lru_cache(maxsize=2 ** 15)
def _compute_one(system: System) -> int:
    if not system:
        return 0
    elif any(eq.illegal for eq in system):
        return sys.maxsize

    n, system = _solve_var(system)
    if n is not None:
        return n + _compute_one(system)

    var, high = _pick_var(system)
    return min(
        i + _compute_one(_substitute(system, var, i))
        for i in range(high + 1)
    )


def _parse_button(s: str) -> frozenset[int]:
    idxs = frozenset(int(n_s) for n_s in s[1:-1].split(','))
    return idxs


def _to_system(
        buttons: list[frozenset[int]],
        target: list[int],
) -> System:
    equations = []
    for i, n in enumerate(target):
        lhs = frozenset(
            Term(letter, 1)
            for letter, button in zip(string.ascii_letters, buttons)
            if i in button
        )
        equations.append(Equation.make(lhs, n))
    lhs = frozenset(
        Term(letter, len(button))
        for letter, button in zip(string.ascii_letters, buttons)
    )
    equations.append(Equation.make(lhs, sum(target)))
    return frozenset(equations)


def compute(s: str) -> int:
    total = 0
    with concurrent.futures.ProcessPoolExecutor() as exe:
        futures = []
        for line in s.splitlines():
            _, *buttons_s, target_s = line.split()

            target = [int(s) for s in target_s[1:-1].split(',')]
            buttons = [_parse_button(s) for s in buttons_s]
            system = _to_system(buttons, target)

            futures.append(exe.submit(_compute_one, system))

        for res in concurrent.futures.as_completed(futures):
            print('.', end='', flush=True)
            total += res.result()
    return total


INPUT_S = '''\
[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
'''
EXPECTED = 33


@pytest.mark.parametrize(
    ('input_s', 'expected'),
    (
        (INPUT_S, EXPECTED),
    ),
)
def test(input_s: str, expected: int) -> None:
    assert compute(input_s) == expected


@pytest.mark.parametrize(
    'eq',
    (
        Equation.make(frozenset((Term('a', 1),)), -1),
        Equation.make(frozenset(), 1),
    ),
)
def test_equation_is_illegal(eq: Equation) -> None:
    assert eq.illegal


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file', nargs='?', default=INPUT_TXT)
    args = parser.parse_args()

    with open(args.data_file) as f, support.timing():
        print(compute(f.read()))

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
