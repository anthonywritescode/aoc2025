CREATE TABLE input (s STRING);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE lines (s STRING);
INSERT INTO lines
SELECT value
FROM json_each((
    SELECT
        '["' || REPLACE(s, char(10), ' ","') || ' "]'
    FROM input
));

CREATE TABLE opstr (s STRING);
INSERT INTO opstr
SELECT s || '+*' FROM lines
ORDER BY ROWID DESC
LIMIT 1;

DELETE FROM lines
ORDER BY ROWID DESC
LIMIT 1;

CREATE TABLE ops (op STRING, s INT, l INT);
WITH RECURSIVE
    nn (s, l, op, rest)
AS (
    SELECT 0, 0, '', s FROM opstr
    UNION ALL
    SELECT
        nn.s + nn.l,
        MIN(INSTR(SUBSTR(rest, 2), '+'), INSTR(SUBSTR(rest, 2), '*')),
        SUBSTR(nn.rest, 1, 1),
        SUBSTR(
            nn.rest,
            MIN(INSTR(SUBSTR(rest, 2), '+'), INSTR(SUBSTR(rest, 2), '*')) + 1
        )
    FROM nn
    WHERE nn.rest != '+*'
)
INSERT INTO ops
SELECT nn.op, nn.s, nn.l FROM nn WHERE nn.op != '';

WITH RECURSIVE
    nn (acc, oprid, linerid, op)
AS (
    SELECT
        (
            SELECT SUBSTR(lines.s, ops.s, ops.l)
            FROM lines INNER JOIN ops
            WHERE lines.ROWID = 1 AND ops.ROWID = 1
        ),
        1,
        1,
        (SELECT op FROM ops WHERE ROWID = 1)
    UNION ALL
    SELECT
        CASE
            WHEN nn.linerid + 1 > (SELECT MAX(ROWID) FROM lines) THEN
                (
                    SELECT SUBSTR(lines.s, ops.s, ops.l)
                    FROM lines INNER JOIN ops
                    WHERE lines.ROWID = 1 AND ops.ROWID = nn.oprid + 1
                )
            WHEN nn.op = '+' THEN
                nn.acc + (
                    SELECT SUBSTR(lines.s, ops.s, ops.l)
                    FROM lines INNER JOIN ops
                    WHERE lines.ROWID = nn.linerid + 1 AND ops.ROWID = nn.oprid
                )
            WHEN nn.op = '*' THEN
                nn.acc * (
                    SELECT SUBSTR(lines.s, ops.s, ops.l)
                    FROM lines INNER JOIN ops
                    WHERE lines.ROWID = nn.linerid + 1 AND ops.ROWID = nn.oprid
                )
            ELSE '???'
        END,
        CASE
            WHEN nn.linerid + 1 > (SELECT MAX(ROWID) FROM lines) THEN
                nn.oprid + 1
            ELSE nn.oprid
        END,
        CASE
            WHEN nn.linerid + 1 > (SELECT MAX(ROWID) FROM lines) THEN 1
            ELSE nn.linerid + 1
        END,
        CASE
            WHEN nn.linerid + 1 > (SELECT MAX(ROWID) FROM lines) THEN
                (SELECT op FROM ops WHERE ROWID = nn.oprid + 1)
            ELSE nn.op
        END
    FROM nn
    WHERE oprid <= (SELECT MAX(ROWID) FROM ops)
)
SELECT SUM(nn.acc) FROM nn WHERE nn.linerid = (SELECT MAX(ROWID) FROM lines);
