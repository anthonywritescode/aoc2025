from __future__ import annotations

import argparse
import math
import os.path
import string
import sys
from typing import Literal
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
    def termsign(self) -> Literal[-1, 0, 1]:
        it = iter(self.terms)
        ret: Literal[-1, 1] = -1 if next(it).k < 0 else 1
        for other in it:
            if ret == 1 and other.k < 0:
                return 0
            elif ret == -1 and other.k > 0:
                return 0
        else:
            return ret

    @property
    def illegal(self) -> bool:
        if not self.terms and self.const:
            return True
        termsign = self.termsign
        return (
            (termsign == 1 and self.const < 0) or
            (termsign == -1 and self.const > 0) or
            (
                len(self.terms) == 1 and
                self.const % next(iter(self.terms)).k != 0
            )
        )

    def solve(self) -> tuple[str, int]:
        term, = self.terms
        assert self.const % term.k == 0, self
        return term.var, self.const // term.k

    def substitute(self, var: str, n: int) -> Self:
        if not any(t.var == var for t in self.terms):
            return self
        removed, = (term for term in self.terms if term.var == var)
        terms = frozenset(term for term in self.terms if term.var != var)
        return type(self)(terms, self.const - removed.k * n)

    def __repr__(self) -> str:
        lhs = ' + '.join(repr(term) for term in sorted(self.terms))
        return f'<{type(self).__name__} {lhs} = {self.const}>'


_TRIVIAL_EQUATION = Equation(frozenset(), 0)


System = frozenset[Equation]


def _substitute(system: System, var: str, n: int) -> System:
    return frozenset(eq.substitute(var, n) for eq in system)


def _pick_var(system: System, bounds: dict[str, int]) -> tuple[str, int]:
    mineq = min(
        system,
        # TODO: I'm getting lucky? this should be `abs(eq.const)`
        # but that makes it 4x slower
        key=lambda eq: (len(eq.terms), eq.const, sorted(eq.terms)),
    )
    var = max(mineq.terms).var

    high = bounds[var]
    for eq in system:
        matching = next((t for t in eq.terms if t.var == var), None)
        if matching is not None:
            termsign = eq.termsign
            if (
                    (termsign == 1 and eq.const >= 0) or
                    (termsign == -1 and eq.const <= 0)
            ):
                high = min(high, abs(eq.const // matching.k))
    return var, high


def _compute_one(system: System, bounds: dict[str, int]) -> int:
    if _TRIVIAL_EQUATION in system:
        system = system - {_TRIVIAL_EQUATION}
    if not system:
        return 0
    elif any(eq.illegal for eq in system):
        return sys.maxsize

    for equation in system:
        if len(equation.terms) == 1:
            var, n = equation.solve()
            return n + _compute_one(_substitute(system, var, n), bounds)
        elif equation.const == 0 and equation.termsign != 0:
            for term in equation.terms:
                system = _substitute(system, term.var, 0)
            return _compute_one(system, bounds)

    var, high = _pick_var(system, bounds)
    return min(
        i + _compute_one(_substitute(system, var, i), bounds)
        for i in range(high + 1)
    )


def _parse_button(s: str) -> frozenset[int]:
    return frozenset(int(n_s) for n_s in s[1:-1].split(','))


def _substitutable(f: list[int], t: list[int]) -> int | None:
    factor = None
    for f_n, t_n in zip(f, t):
        if f_n == 0:
            continue
        elif t_n == 0:
            return None
        elif t_n % f_n == 0:
            factor = t_n // f_n
    else:
        return factor


def _reduce(rows: list[tuple[int, ...]]) -> list[tuple[int, ...]]:
    """roughly translated from wikipedia gaussian elimination"""
    mut = [list(row) for row in rows]
    m = len(mut)
    n = len(mut[0])
    h = k = 0
    while h < m and k < n:
        i_max = max(range(h, m), key=lambda i: mut[i][k])
        if mut[i_max][k] == 0:
            k += 1
        else:
            mut[h], mut[i_max] = mut[i_max], mut[h]
            for i in range(h + 1, m):
                num, den = mut[i][k], mut[h][k]
                mut[i][k] = 0
                for j in range(k + 1, n):
                    mut[i][j] = mut[i][j] * den - mut[h][j] * num
            h += 1
            k += 1

    while mut and not any(mut[-1]):
        mut.pop()

    def _gcd(lst: list[int]) -> None:
        gcd = math.gcd(*lst)
        lst[:] = [n // gcd for n in lst]

    for row in mut:
        _gcd(row)

    for i in reversed(range(1, len(mut))):
        start = next(i for i, val in enumerate(mut[i]) if val)
        chunk = mut[i][start:-1]
        for j in range(i):
            factor = _substitutable(chunk, mut[j][start:-1])
            if factor is not None:
                for k, n in enumerate(chunk):
                    mut[j][start + k] -= factor * n
                mut[j][-1] -= factor * mut[i][-1]
                _gcd(mut[j])

    return [tuple(row) for row in mut]


def _to_system(
        buttons: list[frozenset[int]],
        target: list[int],
) -> tuple[System, dict[str, int]]:
    rows = [
        (*(len(b) for b in buttons), sum(target)),
        *(
            (*(int(i in b) for b in buttons), n)
            for i, n in enumerate(target)
        ),
    ]
    rows = _reduce(rows)
    equations = []
    for row in rows:
        lhs = frozenset(
            Term(letter, k)
            for letter, k in zip(string.ascii_letters, row[:-1])
            if k
        )
        equations.append(Equation(lhs, row[-1]))

    tsum = sum(target)
    bounds = {
        letter: min(
            tsum // len(button),
            min(target[idx] for idx in button),
        )
        for letter, button in zip(string.ascii_letters, buttons)
    }

    return frozenset(equations), bounds


def compute(s: str) -> int:
    total = 0
    for line in s.splitlines():
        _, *buttons_s, target_s = line.split()

        target = [int(s) for s in target_s[1:-1].split(',')]
        buttons = [_parse_button(s) for s in buttons_s]
        system, bounds = _to_system(buttons, target)

        print('.', end='', flush=True)
        total += _compute_one(system, bounds)
        assert total < sys.maxsize
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file', nargs='?', default=INPUT_TXT)
    args = parser.parse_args()

    with open(args.data_file) as f, support.timing():
        print(compute(f.read()))

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
