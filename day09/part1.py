from __future__ import annotations

import argparse
import os.path

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    points = [support.parse_point_comma(line) for line in s.splitlines()]
    return max(
        (abs(p1x - p2x) + 1) * (abs(p1y - p2y) + 1)
        for i, (p1x, p1y) in enumerate(points)
        for p2x, p2y in points[i + 1:]
    )


INPUT_S = '''\
7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3
'''
EXPECTED = 50


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
