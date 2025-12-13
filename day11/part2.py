from __future__ import annotations

import argparse
import functools
import os.path

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
