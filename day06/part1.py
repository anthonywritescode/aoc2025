from __future__ import annotations

import argparse
import math
import os.path
from collections.abc import Callable

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')

OPS: dict[str, Callable[[list[int]], int]] = {'+': sum, '*': math.prod}


def compute(s: str) -> int:
    lines = s.splitlines()
    ops = lines.pop().split()
    all_nums = [support.parse_numbers_split(line) for line in lines]
    pivoted: list[list[int]] = list(zip(*all_nums))  # type: ignore[arg-type]   # mypy doesn't know  # noqa: E501

    total = 0
    for nums, op in zip(pivoted, ops):
        total += OPS[op](nums)
    return total


INPUT_S = '''\
123 328  51 64
 45 64  387 23
  6 98  215 314
*   +   *   +
'''
EXPECTED = 4277556


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
