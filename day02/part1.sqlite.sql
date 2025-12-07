CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE ranges (s INT, e INT);
INSERT INTO ranges
SELECT value->>'[0]', value->>'[1]'
FROM json_each((
    SELECT '[[' || REPLACE(REPLACE(s, ',', '],['), '-', ',') || ']]'
    FROM input
));

WITH RECURSIVE
    nn (n, e)
AS (
    SELECT s, e FROM ranges
    UNION ALL
    SELECT nn.n + 1, e FROM nn
    WHERE nn.n < e
)
SELECT SUM(n) FROM nn
WHERE SUBSTR(n, 1, LENGTH(n) / 2) = SUBSTR(n, LENGTH(n) / 2 + 1);
