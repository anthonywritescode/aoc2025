from __future__ import annotations

import argparse
import os.path

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    count = 0
    pos = 50
    for line in s.splitlines():
        num = int(line[1:])

        count += num // 100
        num = num % 100

        if num:
            prev = pos
            if line[0] == 'L':
                pos -= num
                if pos <= 0 < prev:
                    count += 1
            else:
                pos += num
                if pos >= 100:
                    count += 1
            pos %= 100

    return count


INPUT_S = '''\
L68
L30
R48
L5
R60
L55
L1
L99
R14
L82
'''
EXPECTED = 6


@pytest.mark.parametrize(
    ('input_s', 'expected'),
    (
        (INPUT_S, EXPECTED),
        ('L550', 6),
        ('L50\nR0', 1),
        ('L50\nR100', 2),
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
