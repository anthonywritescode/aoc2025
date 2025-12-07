CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('simple.txt'), char(10)));

CREATE TABLE numbers (n VARCHAR);
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
SELECT nn.n FROM nn WHERE nn.n <= nn.bound;

SELECT sum(n) FROM numbers
WHERE SUBSTR(n, 1, LENGTH(n) / 2) = SUBSTR(n, LENGTH(n) / 2 + 1);
