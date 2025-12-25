from __future__ import annotations

import argparse
import os.path

import support

INPUT_TXT = os.path.join(os.path.dirname(__file__), 'input.txt')


def compute(s: str) -> int:
    *shapes_s, rest = s.split('\n\n')
    shape_sizes = [s.count('#') for s in shapes_s]
    total = 0
    for line in rest.splitlines():
        dims, *shapes_ns = line.split()
        w_s, h_s = dims.rstrip(':').split('x')
        w, h = int(w_s), int(h_s)
        ns = [int(n) for n in shapes_ns]
        fits_easy = w // 3 * h // 3 >= sum(ns)
        possible = w * h
        requested = sum(n * size for n, size in zip(ns, shape_sizes))
        impossible = requested > possible
        if fits_easy:
            total += 1
        elif not impossible:  # the input does not contain any "hard" problems
            raise AssertionError('hard!')
    return total


# no tests today -- the test input is "hard"

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('data_file', nargs='?', default=INPUT_TXT)
    args = parser.parse_args()

    with open(args.data_file) as f, support.timing():
        print(compute(f.read()))

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
