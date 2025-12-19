from __future__ import annotations

import argparse
import collections
import os.path
from collections.abc import Callable

import pytest

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    edges = {}
    for line in s.splitlines():
        k, rest = line.split(': ')
        edges[k] = rest.split()

    paths = set()
    todo: collections.deque[tuple[str, ...]] = collections.deque([('you',)])
    while todo:
        path = todo.popleft()
        if path[-1] == 'out':
            paths.add(path)
        else:
            for cand in edges[path[-1]]:
                todo.append((*path, cand))
    return len(paths)


def compute_sqlike(s: str) -> int:
    edges = {}
    for line in s.splitlines():
        k, rest = line.split(': ')
        edges[k] = rest.split()

    seen = {(k, 'out') for k in edges}

    unknown = set(seen)
    known = {('out', 'out'): 1}

    while unknown:
        removed = []
        for (k, v) in unknown:
            if all((u, v) in known for u in edges[k]):
                removed.append((k, v))
                known[(k, v)] = sum(known[(u, v)] for u in edges[k])
        unknown.difference_update(removed)

    return known[('you', 'out')]


INPUT_S = '''\
aaa: you hhh
you: bbb ccc
bbb: ddd eee
ccc: ddd eee fff
ddd: ggg
eee: out
fff: out
ggg: out
hhh: ccc fff iii
iii: out
'''
EXPECTED = 5


@pytest.mark.parametrize(
    ('input_s', 'expected'),
    (
        (INPUT_S, EXPECTED),
    ),
)
@pytest.mark.parametrize('fn', (compute, compute_sqlike))
def test(input_s: str, expected: int, fn: Callable[[str], int]) -> None:
    assert fn(input_s) == expected


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file', nargs='?', default=INPUT_TXT)
    args = parser.parse_args()

    with open(args.data_file) as f, support.timing():
        print(compute(f.read()))

    with open(args.data_file) as f, support.timing('sqlike'):
        print(compute_sqlike(f.read()))

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
