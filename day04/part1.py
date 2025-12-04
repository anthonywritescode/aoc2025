from __future__ import annotations

import argparse
import os.path
from collections.abc import Callable

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    total = 0
    lines = s.splitlines()
    for y, line in enumerate(lines):
        for x, c in enumerate(line):
            if c == '@':
                around = sum(
                    lines[yc][xc] == '@'
                    for xc, yc in support.adjacent_8(x, y)
                    if 0 <= xc < len(lines[0])
                    if 0 <= yc < len(lines)
                )
                if around < 4:
                    total += 1
    return total


def compute_heatmap(s: str) -> int:
    points = support.parse_coords_hash(s, wall='@')
    counts = {k: 0 for k in points}
    for x, y in points:
        for xc, yc in support.adjacent_8(x, y):
            if (xc, yc) in points:
                counts[(xc, yc)] += 1
    return sum(val < 4 for val in counts.values())


INPUT_S = '''\
..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@.
'''
EXPECTED = 13


@pytest.mark.parametrize(
    ('input_s', 'expected'),
    (
        (INPUT_S, EXPECTED),
    ),
)
@pytest.mark.parametrize('fn', (compute, compute_heatmap))
def test(input_s: str, expected: int, fn: Callable[[str], int]) -> None:
    assert compute(input_s) == expected


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file', nargs='?', default=INPUT_TXT)
    args = parser.parse_args()

    with open(args.data_file) as f, support.timing():
        print(compute(f.read()))

    with open(args.data_file) as f, support.timing():
        print(compute_heatmap(f.read()))

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
