CREATE TABLE input (n INT, s VARCHAR);
-- adjust `n` for part 1 (2) or part 2 (12)
INSERT INTO input VALUES (12, TRIM(readfile('input.txt'), char(10)));

CREATE TABLE lines (s VARCHAR);
INSERT INTO lines
SELECT value FROM json_each((
    SELECT '["' || REPLACE(s, char(10), '","') || '"]' FROM input
));

WITH RECURSIVE nn (chars, i, j, left, line, n) AS (
    SELECT '', 0, 0, 0, s, (SELECT n FROM input) FROM lines
    UNION ALL
    SELECT
        -- chars
        CASE
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN
                nn.chars || SUBSTR(nn.line, nn.left + 1, 1)
            ELSE nn.chars
        END,
        -- i
        CASE
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN nn.i + 1
            ELSE nn.i
        END,
        -- j
        CASE
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN 0
            ELSE nn.j + 1
        END,
        -- left
        CASE
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
            WHEN nn.j >= LENGTH(nn.line) - (nn.n - nn.i) + 1 THEN
                SUBSTR(nn.line, nn.left + 2)
            ELSE nn.line
        END,
        -- n
        nn.n
    FROM nn
    WHERE nn.i < nn.n
)
SELECT SUM(chars) FROM nn WHERE nn.i = nn.n
