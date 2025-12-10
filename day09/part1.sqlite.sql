CREATE TABLE input (n INT, s VARCHAR);
INSERT INTO input VALUES (1000, TRIM(readfile('input.txt'), char(10)));

CREATE TABLE points (x INT, y INT);
INSERT INTO points
SELECT value->>'[0]', value->>'[1]'
FROM json_each((
    SELECT '[[' || REPLACE(s, char(10), '],[') || ']]'
    FROM input
));

SELECT MAX((ABS(p1.x - p2.x) + 1) * (ABS(p1.y - p2.y) + 1))
FROM points p1
INNER JOIN points p2 ON p2.ROWID > p1.ROWID;
