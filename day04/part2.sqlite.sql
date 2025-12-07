CREATE TABLE input (s VARCHAR);
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

WITH RECURSIVE
    nn (total, state)
AS (
    SELECT 0, (SELECT json_group_array(json_array(x, y, n)) FROM counts)
    UNION ALL
    SELECT
        -- total
        nn.total + (
            SELECT COUNT(1) FROM json_each(nn.state)
            WHERE value->>'[2]' < 4
        ),
        -- state
        (
            SELECT json_group_array(json(r)) FROM (
                SELECT json_array(x, y, SUM(n)) AS r
                FROM (
                    -- existing data
                    SELECT
                        value->>'[0]' AS x,
                        value->>'[1]' AS y,
                        value->>'[2]' AS n
                    FROM json_each(nn.state)
                    WHERE value->>'[2]' >= 4

                    UNION ALL

                    -- subtractions
                    SELECT
                        value->>'[0]' + dx AS x,
                        value->>'[1]' + dy AS y,
                        -1 AS n
                    FROM json_each(nn.state)
                    INNER JOIN adj8
                    INNER JOIN coords ON
                        coords.x = value->>'[0]' + dx AND
                        coords.y = value->>'[1]' + dy
                    WHERE value->>'[2]' < 4
                ) _
                GROUP BY x, y
            ) _2
            -- if we delete two adjacent some things go negative :(
            WHERE json(r)->>'[2]' >= 0
        )
    FROM nn
    WHERE (
        SELECT COUNT(1) FROM json_each(nn.state)
        WHERE value->>'[2]' < 4
    ) > 0
)
SELECT MAX(total) FROM nn;
