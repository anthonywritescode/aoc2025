CREATE TABLE input (n INT, s VARCHAR);
-- adjust `n` for part 1 (2) or part 2 (12)
INSERT INTO input VALUES (12, TRIM(readfile('input.txt'), char(10)));

WITH RECURSIVE
    nn (chars, i, j, left, line, rest, n, dbg)
AS (
    SELECT
        '', 0, 0, 0,
        (SELECT SUBSTR(s, 0, INSTR(s, char(10))) FROM INPUT),
        (SELECT SUBSTR(s || char(10), INSTR(s, char(10)) + 1) FROM input),
        (SELECT n FROM input), NULL
    UNION ALL
    SELECT
        -- chars
        CASE
            WHEN nn.i >= nn.n THEN ''
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN
                nn.chars || SUBSTR(nn.line, nn.left + 1, 1)
            ELSE nn.chars
        END,
        -- i
        CASE
            WHEN nn.i >= nn.n THEN 0
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN nn.i + 1
            ELSE nn.i
        END,
        -- j
        CASE
            WHEN nn.i >= nn.n THEN 0
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN 0
            ELSE nn.j + 1
        END,
        -- left
        CASE
            WHEN nn.i >= nn.n THEN 0
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN 0
            WHEN (
                SUBSTR(nn.line, nn.j + 1, 1) >
                SUBSTR(nn.line, nn.left + 1, 1)
            ) THEN
                nn.j
            ELSE nn.left
        END,
        -- line
        CASE
            WHEN nn.i >= nn.n THEN
                SUBSTR(nn.rest, 0, INSTR(nn.rest, char(10)))
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN
                SUBSTR(nn.line, nn.left + 2)
            ELSE nn.line
        END,
        -- rest and n
        CASE
            WHEN nn.i >= nn.n THEN
                SUBSTR(nn.rest, INSTR(nn.rest, char(10)) + 1)
            ELSE nn.rest
        END,
        nn.n, SUBSTR(nn.line, nn.j + 1, 1)
    FROM nn
    WHERE nn.i < nn.n OR nn.rest != ''
)
SELECT SUM(chars) FROM nn WHERE nn.i >= nn.n
