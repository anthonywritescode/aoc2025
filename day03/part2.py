from __future__ import annotations

import argparse
import os.path

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str, *, n: int = 12) -> int:
    total = 0
    for line in s.splitlines():
        chars = []
        for i in range(n):
            left = 0
            for j in range(1, len(line) - (n - i) + 1):
                if line[j] > line[left]:
                    left = j
            chars.append(line[left])
            line = line[left + 1:]
        total += int(''.join(chars))
    return total


INPUT_S = '''\
987654321111111
811111111111119
234234234234278
818181911112111
'''
EXPECTED = 3121910778619


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
