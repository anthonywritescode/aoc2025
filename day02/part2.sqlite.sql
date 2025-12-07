CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE ranges (s INT, e INT);
INSERT INTO ranges
SELECT value->>'[0]', value->>'[1]'
FROM json_each((
    SELECT '[[' || REPLACE(REPLACE(s, ',', '],['), '-', ',') || ']]'
    FROM input
));

CREATE TABLE numbers (n VARCHAR, l2 INT);
WITH RECURSIVE
    nn (n, e)
AS (
    SELECT s, e FROM ranges
    UNION ALL
    SELECT nn.n + 1, e FROM nn
    WHERE nn.n < e
)
INSERT INTO numbers
SELECT nn.n, LENGTH(nn.n) / 2 FROM nn;

CREATE TABLE answers(n INT);
WITH RECURSIVE
    nn (chunksize, arr, rest, n, l2)
AS (
    SELECT 1, json_array(), n, n, l2 FROM numbers
    UNION ALL
    SELECT
        CASE
            WHEN nn.rest = '' THEN nn.chunksize + 1
            ELSE nn.chunksize
        END,
        CASE
            WHEN nn.rest = '' THEN json_array()
            ELSE json_insert(nn.arr, '$[#]', SUBSTR(nn.rest, 1, nn.chunksize))
        END,
        CASE
            WHEN nn.rest = '' THEN nn.n
            ELSE SUBSTR(nn.rest, 1 + nn.chunksize)
        END,
        nn.n,
        nn.l2
    FROM nn
    WHERE nn.chunksize <= nn.l2
)
SELECT SUM(DISTINCT nn.n) FROM nn
WHERE
    nn.rest = '' AND
    (SELECT COUNT(DISTINCT value) FROM json_each(nn.arr)) = 1
;
