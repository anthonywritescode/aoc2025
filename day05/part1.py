from __future__ import annotations

import argparse
import os.path

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    ranges_s, rest = s.split('\n\n')

    ranges = []
    for line in ranges_s.splitlines():
        start_s, end_s = line.split('-')
        ranges.append(range(int(start_s), int(end_s) + 1))

    return sum(
        any(int(line) in r for r in ranges)
        for line in rest.splitlines()
    )


INPUT_S = '''\
3-5
10-14
16-20
12-18

1
5
8
11
17
32
'''
EXPECTED = 3


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
