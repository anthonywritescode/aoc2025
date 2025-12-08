from __future__ import annotations

import argparse
import math
import os.path
from typing import NamedTuple
from typing import Self

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


class Point(NamedTuple):
    x: int
    y: int
    z: int

    def distance(self, other: Point) -> int:
        return sum((sv - ov) ** 2 for sv, ov in zip(self, other))

    @classmethod
    def parse(cls, s: str) -> Self:
        xs, ys, zs = s.split(',')
        return cls(int(xs), int(ys), int(zs))


def compute(s: str, *, n: int = 1000) -> int:
    points = [Point.parse(line) for line in s.splitlines()]

    distances = []
    for i, p1 in enumerate(points):
        for j, p2 in enumerate(points[i + 1:], i + 1):
            distances.append((p1.distance(p2), i, j))
    distances.sort(reverse=True)

    connected: dict[int, set[int]] = {}
    for _ in range(n):
        _, i, j = distances.pop()
        if i in connected and j in connected and connected[i] is connected[j]:
            pass
        elif i in connected and j in connected:
            newset = connected[i] | connected[j]
            connected.update({p: newset for p in newset})
        elif i in connected:
            connected[j] = connected[i]
            connected[j].add(j)
        elif j in connected:
            connected[i] = connected[j]
            connected[i].add(i)
        else:
            connected[i] = connected[j] = {i, j}

    uniques = {id(v): v for v in connected.values()}
    largest = sorted([len(v) for v in uniques.values()], reverse=True)
    return math.prod(largest[:3])


INPUT_S = '''\
162,817,812
57,618,57
906,360,560
592,479,940
352,342,300
466,668,158
542,29,236
431,825,988
739,650,466
52,470,668
216,146,977
819,987,18
117,168,530
805,96,715
346,949,466
970,615,88
941,993,340
862,61,35
984,92,344
425,690,689
'''
EXPECTED = 40


@pytest.mark.parametrize(
    ('input_s', 'expected'),
    (
        (INPUT_S, EXPECTED),
    ),
)
def test(input_s: str, expected: int) -> None:
    assert compute(input_s, n=10) == expected


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file', nargs='?', default=INPUT_TXT)
    args = parser.parse_args()

    with open(args.data_file) as f, support.timing():
        print(compute(f.read()))

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
