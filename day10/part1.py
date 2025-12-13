from __future__ import annotations

import argparse
import collections
import os.path

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def _compute_one(target: int, buttons: tuple[int, ...]) -> int:
    todo = collections.deque([(0, 0)])
    seen = set()
    while todo:
        size, n = todo.popleft()
        if n == target:
            return size
        elif n in seen:
            continue
        else:
            seen.add(n)
        for button in buttons:
            todo.append((size + 1, n ^ button))
    raise AssertionError('unreachable!')


def _parse_button(s: str) -> int:
    return sum(1 << int(n_s) for n_s in s[1:-1].split(','))


def compute(s: str) -> int:
    total = 0
    for line in s.splitlines():
        target_s, *buttons_s, _ = line.split()
        target_bin = target_s[1:-1][::-1].replace('.', '0').replace('#', '1')

        target = int(target_bin, 2)
        buttons = tuple(_parse_button(s) for s in buttons_s)

        total += _compute_one(target, buttons)
    return total


INPUT_S = '''\
[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
'''
EXPECTED = 7


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
