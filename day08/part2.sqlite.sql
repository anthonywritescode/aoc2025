CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE points (x INT, y INT, z INT);
INSERT INTO points
SELECT value->>'[0]', value->>'[1]', value->>'[2]'
FROM json_each((
    SELECT '[[' || REPLACE(s, char(10), '],[') || ']]'
    FROM input
));

CREATE TABLE distances (d INT, p1 INT, p2 INT);
INSERT INTO distances
SELECT d, p1, p2 FROM (
    SELECT
        (
            pow((p1.x - p2.x), 2) +
            pow((p1.y - p2.y), 2) +
            pow((p1.z - p2.z), 2)
        ) AS d,
        p1.ROWID AS p1,
        p2.ROWID AS p2
    FROM points p1
    INNER JOIN points p2 ON p2.ROWID > p1.ROWID
)
ORDER BY d;

CREATE TABLE final(n);
WITH RECURSIVE nn (i, arrs, p1, p2) AS (
    SELECT
        ROWID,
        (SELECT json_group_array(json_array(ROWID)) FROM points),
        p1,
        p2
    FROM distances WHERE ROWID = 1
    UNION ALL
    SELECT
        nn.i + 1,
        (
            SELECT json_group_array(json(arr)) FROM (
                -- all the arrays not containing the two points
                SELECT value AS arr
                FROM json_each(nn.arrs) AS o
                WHERE NOT EXISTS(
                    SELECT 1 FROM json_each(o.value) AS i
                    WHERE i.value == nn.p1 OR i.value == nn.p2
                )
                UNION ALL
                -- a single array joining the arrays containing the two points
                SELECT json_group_array(value) FROM (
                    SELECT value FROM json_each((
                        SELECT value FROM json_each(nn.arrs) AS o
                        WHERE EXISTS (
                            SELECT 1 FROM json_each(o.value) as i
                            WHERE i.value == nn.p1
                        )
                    ))
                    UNION
                    SELECT value FROM json_each((
                        SELECT value FROM json_each(nn.arrs) AS o
                        WHERE EXISTS (
                            SELECT 1 FROM json_each(o.value) as i
                            WHERE i.value == nn.p2
                        )
                   ))
                )
            )
        ),
        (SELECT p1 FROM distances WHERE ROWID = nn.i + 1),
        (SELECT p2 FROM distances WHERE ROWID = nn.i + 1)
    FROM nn
    WHERE json_array_length(nn.arrs) != 1
)
INSERT INTO final
SELECT MAX(nn.i) - 1 FROM nn;

SELECT p1.x * p2.x FROM final
INNER JOIN distances ON distances.ROWID = final.n
INNER JOIN points AS p1 ON p1.ROWID = distances.p1
INNER JOIN points AS p2 ON p2.ROWID = distances.p2;
