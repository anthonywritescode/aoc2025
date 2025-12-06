from __future__ import annotations

import argparse
import math
import os.path
import re
from collections.abc import Callable

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')

OPS: dict[str, Callable[[list[int]], int]] = {'+': sum, '*': math.prod}
PAT = re.compile(r'([+*])([ ]+)')


def compute(s: str) -> int:
    *lines, opline = s.splitlines()
    offset = 0
    numstrs = []
    while offset < len(opline):
        match = PAT.match(opline, offset)
        assert match is not None, match
        strs = [s[match.start():match.end()] for s in lines]
        numstrs.append((strs, OPS[match[1]]))
        offset = match.end()

    total = 0
    for strs, op in numstrs:
        nums = [
            int(''.join(digits).strip())
            for digits in zip(*strs)
            if ''.join(digits).strip()
        ]
        total += op(nums)

    return total


INPUT_S = (
    '123 328  51 64 \n'
    ' 45 64  387 23 \n'
    '  6 98  215 314\n'
    '*   +   *   +  \n'
)
EXPECTED = 3263827


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
