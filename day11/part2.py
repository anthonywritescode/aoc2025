from __future__ import annotations

import argparse
import functools
import os.path
from collections.abc import Callable

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    edges = {}
    for line in s.splitlines():
        k, rest = line.split(': ')
        edges[k] = rest.split()

    @functools.cache
    def _paths(f: str, t: str) -> int:
        if f == t:
            return 1
        elif f == 'out':
            return 0
        else:
            return sum(_paths(cand, t) for cand in edges[f])

    return (
        _paths('svr', 'dac') * _paths('dac', 'fft') * _paths('fft', 'out') +
        _paths('svr', 'fft') * _paths('fft', 'dac') * _paths('dac', 'out')
    )


def compute_sqlike(s: str) -> int:
    edges = {}
    for line in s.splitlines():
        k, rest = line.split(': ')
        edges[k] = rest.split()

    seen = {(k, 'out') for k in edges}

    unknown = set(seen)
    known = {('out', 'out'): 1}

    while unknown:
        removed = []
        for (k, v) in unknown:
            if all((u, v) in known for u in edges[k]):
                removed.append((k, v))
                known[(k, v)] = sum(known[(u, v)] for u in edges[k])
        unknown.difference_update(removed)

    fft_out = known[('fft', 'out')]
    dac_out = known[('dac', 'out')]

    unknown = {(k, 'fft') for k in edges if k != 'fft'}
    known = {('fft', 'fft'): 1, ('out', 'fft'): 0}

    while unknown:
        removed = []
        for (k, v) in unknown:
            if all((u, v) in known for u in edges[k]):
                removed.append((k, v))
                known[(k, v)] = sum(known[(u, v)] for u in edges[k])
        unknown.difference_update(removed)

    svr_fft = known[('svr', 'fft')]
    dac_fft = known[('dac', 'fft')]

    unknown = {(k, 'dac') for k in edges if k != 'dac'}
    known = {('dac', 'dac'): 1, ('out', 'dac'): 0}

    while unknown:
        removed = []
        for (k, v) in unknown:
            if all((u, v) in known for u in edges[k]):
                removed.append((k, v))
                known[(k, v)] = sum(known[(u, v)] for u in edges[k])
        unknown.difference_update(removed)

    svr_dac = known[('svr', 'dac')]
    fft_dac = known[('fft', 'dac')]

    return (svr_dac * dac_fft * fft_out + svr_fft * fft_dac * dac_out)


INPUT_S = '''\
svr: aaa bbb
aaa: fft
fft: ccc
bbb: tty
tty: ccc
ccc: ddd eee
ddd: hub
hub: fff
eee: dac
dac: fff
fff: ggg hhh
ggg: out
hhh: out
'''
EXPECTED = 2


@pytest.mark.parametrize(
    ('input_s', 'expected'),
    (
        (INPUT_S, EXPECTED),
    ),
)
@pytest.mark.parametrize('fn', (compute, compute_sqlike))
def test(input_s: str, expected: int, fn: Callable[[str], int]) -> None:
    assert fn(input_s) == expected


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file', nargs='?', default=INPUT_TXT)
    args = parser.parse_args()

    with open(args.data_file) as f, support.timing():
        print(compute(f.read()))

    with open(args.data_file) as f, support.timing('sqlike'):
        print(compute_sqlike(f.read()))

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
