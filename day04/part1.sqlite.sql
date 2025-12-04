CREATE TABLE input (s STRING);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE coords (x INT, y INT);
WITH RECURSIVE
    nn (y, x, wall, rest)
AS (
    SELECT 0, -1, FALSE, (SELECT s || char(10) FROM input)
    UNION ALL
    SELECT
        CASE SUBSTR(nn.rest, 1, 1) WHEN char(10) THEN nn.y + 1 ELSE nn.y END,
        CASE SUBSTR(nn.rest, 1, 1) WHEN char(10) THEN -1 ELSE nn.x + 1 END,
        SUBSTR(nn.rest, 1, 1) = '@',
        SUBSTR(nn.rest, 2)
    FROM nn
    WHERE nn.rest != ''
)
INSERT INTO coords
SELECT x, y FROM nn WHERE nn.wall;

CREATE TABLE adj8 (dx INT, dy INT);
INSERT INTO adj8 VALUES
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, -1),
    --(0, 0)
    (0, 1),
    (1, -1),
    (1, 0),
    (1, 1)
;

CREATE TABLE counts (x INT, y INT, n INT, PRIMARY KEY (x, y));
INSERT INTO counts SELECT x, y, 0 FROM coords;
INSERT OR REPLACE INTO counts
SELECT coords.x + dx, coords.y + dy, SUM(1)
FROM coords
INNER JOIN adj8
INNER JOIN coords AS coords2 ON
    coords.x + dx = coords2.x AND coords.y + dy = coords2.y
GROUP BY coords.x + dx, coords.y + dy;

SELECT COUNT(1) FROM counts WHERE counts.n < 4;
