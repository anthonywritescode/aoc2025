from __future__ import annotations

import argparse
import itertools
import math
import os.path
from typing import NamedTuple
from typing import Self

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


class HLine(NamedTuple):
    y: int
    x1: int
    x2: int

    @classmethod
    def make(cls, p1: tuple[int, int], p2: tuple[int, int]) -> Self:
        assert p1[1] == p2[1], (p1, p2)
        return cls(p1[1], min(p1[0], p2[0]), max(p1[0], p2[0]))


class VLine(NamedTuple):
    x: int
    y1: int
    y2: int

    @classmethod
    def make(cls, p1: tuple[int, int], p2: tuple[int, int]) -> Self:
        assert p1[0] == p2[0], (p1, p2)
        return cls(p1[0], min(p1[1], p2[1]), max(p1[1], p2[1]))


def _intersects(h: HLine, v: VLine) -> bool:
    return (
        h.x1 < v.x < h.x2 and
        v.y1 < h.y < v.y2
    )


def _distance(p1: tuple[int, ...], p2: tuple[int, ...]) -> int:
    return math.prod(abs(part1 - part2) + 1 for part1, part2 in zip(p1, p2))


def _contains(
        p1: tuple[int, ...],
        p2: tuple[int, ...],
        p3: tuple[int, ...],
) -> bool:
    mins = [min(part) for part in zip(p1, p2)]
    maxs = [max(part) for part in zip(p1, p2)]
    return all(
        min_part < part < max_part
        for min_part, max_part, part in zip(mins, maxs, p3)
    )


def _direction(p1: tuple[int, int], p2: tuple[int, int]) -> support.Direction4:
    p1x, p1y = p1
    p2x, p2y = p2

    if p1x == p2x:
        if p1y < p2y:
            return support.Direction4.DOWN
        else:
            return support.Direction4.UP
    else:
        if p1x < p2x:
            return support.Direction4.RIGHT
        else:
            return support.Direction4.LEFT


def compute(s: str) -> int:
    points = [support.parse_point_comma(line) for line in s.splitlines()]

    cw = 0
    ccw = 0
    prev_p = points[1]
    prev_d = _direction(points[0], points[1])
    for p in itertools.chain(points[2:], points[:2]):
        d = _direction(prev_p, p)
        if prev_d.ccw is d:
            ccw += 1
        elif prev_d.cw is d:
            cw += 1
        else:
            raise AssertionError('unreachable!')
        prev_p, prev_d = p, d

    assert min(cw, ccw) + 4 == max(cw, ccw), (cw, ccw)
    clockwise = cw > ccw

    vertical = []
    horizontal = []
    outside = []
    prev_p = points[1]
    prev_d = _direction(points[0], points[1])
    for p in itertools.chain(points[2:], points[:2]):
        d = _direction(prev_p, p)
        if clockwise:
            if prev_d.ccw is d:
                outside.append(prev_d.opposite.apply(*d.apply(*prev_p)))
            else:
                outside.append(prev_d.apply(*d.opposite.apply(*prev_p)))
        else:
            if prev_d.cw is d:
                outside.append(prev_d.opposite.apply(*d.apply(*prev_p)))
            else:
                outside.append(prev_d.apply(*d.opposite.apply(*prev_p)))
        if d in (support.Direction4.UP, support.Direction4.DOWN):
            vertical.append(VLine.make(prev_p, p))
        else:
            horizontal.append(HLine.make(prev_p, p))
        prev_p, prev_d = p, d

    best = -1
    for i, p1 in enumerate(points):
        for p2 in points[i + 1:]:
            for p3 in itertools.chain(points, outside):
                if p3 is p1 or p3 is p2:
                    continue
                elif _contains(p1, p2, p3):
                    break
            else:
                shape_v = [
                    VLine.make(p1, (p1[0], p2[1])),
                    VLine.make(p2, (p2[0], p1[1])),
                ]
                shape_h = [
                    HLine.make(p1, (p2[0], p1[1])),
                    HLine.make(p2, (p1[0], p2[1])),
                ]

                if (
                    not any(
                        _intersects(h, v) for h in shape_h for v in vertical
                    ) and
                    not any(
                        _intersects(h, v) for h in horizontal for v in shape_v
                    )
                ):
                    best = max(best, _distance(p1, p2))

    return best


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
EXPECTED = 24

INPUT2 = '''\
1,8
2,8
2,9
10,9
10,1
11,1
11,11
1,11
'''
EXPECTED2 = 30

INPUT3 = '''\
0,0
60,0
60,2
61,2
61,51
3,51
3,1
2,1
2,51
1,51
1,50
0,50
'''
EXPECTED3 = 3016


@pytest.mark.parametrize(
    ('input_s', 'expected'),
    (
        (INPUT_S, EXPECTED),
        (INPUT2, EXPECTED2),
        (INPUT3, EXPECTED3),
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
