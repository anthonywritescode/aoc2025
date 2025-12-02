CREATE TABLE input (s STRING);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE numbers (n STRING, l2 INT);
WITH RECURSIVE
    nn (n, bound, rest)
AS (
    SELECT 1, 0, (SELECT s || ',' FROM input)
    UNION ALL
    SELECT
        CASE
            WHEN nn.n > nn.bound THEN
                1 * SUBSTR(nn.rest, 1, INSTR(nn.rest, '-') - 1)
            ELSE nn.n + 1
        END,
        CASE
            WHEN nn.n > nn.bound THEN
                1 * SUBSTR(
                    nn.rest,
                    INSTR(nn.rest, '-') + 1,
                    INSTR(nn.rest, ',') - INSTR(nn.rest, '-') - 1
                )
            ELSE nn.bound
        END,
        CASE
            WHEN nn.n > nn.bound THEN SUBSTR(nn.rest, INSTR(nn.rest, ',') + 1)
            ELSE nn.rest
        END
    FROM nn
    WHERE nn.n <= bound OR nn.rest != ''
)
INSERT INTO numbers
SELECT nn.n, LENGTH(nn.n) / 2 FROM nn
WHERE nn.n <= nn.bound AND LENGTH(nn.n) > 1;

CREATE TABLE answers(rid INT);
WITH RECURSIVE
    nn (rid, chunksize, arr, rest)
AS (
    SELECT 1, 1, json_array(), (SELECT n FROM numbers WHERE ROWID = 1)
    UNION ALL
    SELECT
        CASE
            WHEN (
                nn.rest = '' AND
                nn.chunksize >= (SELECT l2 FROM numbers WHERE ROWID = nn.rid)
            )
            THEN nn.rid + 1
            ELSE nn.rid
        END,
        CASE
            WHEN (
                nn.rest = '' AND
                nn.chunksize >= (SELECT l2 FROM numbers WHERE ROWID = nn.rid)
            )
            THEN 1
            WHEN nn.rest = '' THEN nn.chunksize + 1
            ELSE nn.chunksize
        END,
        CASE
            WHEN nn.rest = '' THEN json_array()
            ELSE json_insert(nn.arr, '$[#]', SUBSTR(nn.rest, 1, nn.chunksize))
        END,
        CASE
            WHEN (
                nn.rest = '' AND
                nn.chunksize >= (SELECT l2 FROM numbers WHERE ROWID = nn.rid)
            )
            THEN (SELECT n FROM numbers WHERE ROWID = nn.rid + 1)
            WHEN nn.rest = '' THEN (SELECT n FROM numbers WHERE ROWID = nn.rid)
            ELSE SUBSTR(nn.rest, 1 + nn.chunksize)
        END
    FROM nn
    WHERE nn.rid <= (SELECT MAX(ROWID) FROM numbers) OR nn.rest != ''
)
INSERT INTO answers
SELECT nn.rid FROM nn
WHERE
    nn.rest = '' AND
    (SELECT COUNT(DISTINCT value) FROM json_each(nn.arr)) = 1
GROUP BY nn.rid;

SELECT SUM(numbers.n) FROM answers
INNER JOIN numbers ON answers.rid = numbers.ROWID;
