from __future__ import annotations

import argparse
import os.path

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    prev = -1
    total = 0
    lines = [list(line) for line in s.splitlines()]
    while prev != total:
        prev = total
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
                        lines[y][x] = '.'
    return total


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
EXPECTED = 43


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
