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

    unknown = set(edges)
    known = {'out': 1}

    while unknown:
        removed = []
        for k in unknown:
            if all(v in known for v in edges[k]):
                removed.append(k)
                known[k] = sum(known[u] for u in edges[k])
        unknown.difference_update(removed)

    fft_out = known['fft']
    dac_out = known['dac']

    unknown = set(edges) - {'fft'}
    known = {'fft': 1, 'out': 0}

    while unknown:
        removed = []
        for k in unknown:
            if all(v in known for v in edges[k]):
                removed.append(k)
                known[k] = sum(known[u] for u in edges[k])
        unknown.difference_update(removed)

    svr_fft = known['svr']
    dac_fft = known['dac']

    unknown = set(edges) - {'dac'}
    known = {'dac': 1, 'out': 0}

    while unknown:
        removed = []
        for k in unknown:
            if all(v in known for v in edges[k]):
                removed.append(k)
                known[k] = sum(known[u] for u in edges[k])
        unknown.difference_update(removed)

    svr_dac = known['svr']
    fft_dac = known['fft']

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
