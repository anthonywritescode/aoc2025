from __future__ import annotations

import argparse
import os.path

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    total = 0
    for line in s.splitlines():
        d1 = max(line)
        idx = line.index(d1)
        if idx == len(line) - 1:
            d1, d2 = max(line[:-1]), d1
        else:
            d2 = max(line[line.index(d1) + 1:])
        total += int(d1 + d2)
    return total


INPUT_S = '''\
987654321111111
811111111111119
234234234234278
818181911112111
'''
EXPECTED = 357


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
