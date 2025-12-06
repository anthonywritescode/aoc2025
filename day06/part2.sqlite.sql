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
    SELECT 1, 0, '', s FROM opstr
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

CREATE TABLE numstrs(oprid INT, numstrs VARCHAR);
WITH RECURSIVE
    nn (numstr, oprid, linerid)
AS (
    SELECT
        (
            SELECT SUBSTR(lines.s, ops.s, ops.l - 1)
            FROM lines INNER JOIN ops
            WHERE lines.ROWID = 1 AND ops.ROWID = 1
        ),
        1,
        1
    UNION ALL
    SELECT
        CASE
            WHEN nn.linerid + 1 > (SELECT MAX(ROWID) FROM lines) THEN
                (
                    SELECT SUBSTR(lines.s, ops.s, ops.l)
                    FROM lines INNER JOIN ops
                    WHERE lines.ROWID = 1 AND ops.ROWID = nn.oprid + 1
                )
            ELSE
                (
                    SELECT SUBSTR(lines.s, ops.s, ops.l)
                    FROM lines INNER JOIN ops
                    WHERE lines.ROWID = nn.linerid + 1 AND ops.ROWID = nn.oprid
                )
        END,
        CASE
            WHEN nn.linerid + 1 > (SELECT MAX(ROWID) FROM lines) THEN
                nn.oprid + 1
            ELSE nn.oprid
        END,
        CASE
            WHEN nn.linerid + 1 > (SELECT MAX(ROWID) FROM lines) THEN 1
            ELSE nn.linerid + 1
        END
    FROM nn
    WHERE oprid <= (SELECT MAX(ROWID) FROM ops)
)
INSERT INTO numstrs
SELECT nn.oprid, json_group_array(nn.numstr)
FROM nn WHERE nn.oprid <= (SELECT MAX(ROWID) FROM ops)
GROUP BY nn.oprid;

WITH RECURSIVE
    nn (acc, oprid, i, l, op)
AS (
    SELECT
        (
            SELECT (
                SELECT group_concat(SUBSTR(value, 1, 1), '')
                FROM json_each(numstrs.numstrs)
            )
            FROM numstrs WHERE ROWID = 1
        ),
        oprid,
        1,
        (SELECT ops.l FROM ops WHERE ROWID = 1),
        (SELECT ops.op FROM ops WHERE ROWID = 1)
    FROM numstrs WHERE oprid = 1
    UNION ALL
    SELECT
        CASE
            WHEN nn.i + 1 >= nn.l THEN
                (
                    SELECT (
                        SELECT group_concat(SUBSTR(value, 1, 1), '')
                        FROM json_each(numstrs.numstrs)
                    )
                    FROM numstrs WHERE numstrs.oprid = nn.oprid + 1
                )
            WHEN nn.op = '+' THEN
                nn.acc + (
                    SELECT (
                        SELECT group_concat(SUBSTR(value, i + 1, 1), '')
                        FROM json_each(numstrs.numstrs)
                    )
                    FROM numstrs WHERE ROWID = nn.oprid
                )
            WHEN nn.op = '*' THEN
                nn.acc * (
                    SELECT (
                        SELECT group_concat(SUBSTR(value, i + 1, 1), '')
                        FROM json_each(numstrs.numstrs)
                    )
                    FROM numstrs WHERE ROWID = nn.oprid
                )
            ELSE '???'
        END,
        CASE
            WHEN nn.i + 1 >= nn.l THEN nn.oprid + 1
            ELSE nn.oprid
        END,
        CASE
            WHEN nn.i + 1 >= nn.l THEN 1
            ELSE nn.i + 1
        END,
        CASE
            WHEN nn.i + 1 >= nn.l THEN
                (SELECT ops.l FROM ops WHERE ROWID = nn.oprid + 1)
            ELSE nn.l
        END,
        CASE
            WHEN nn.i + 1 >= nn.l THEN
                (SELECT ops.op FROM ops WHERE ROWID = nn.oprid + 1)
            ELSE nn.op
        END
    FROM nn
    WHERE nn.oprid <= (SELECT MAX(oprid) FROM numstrs)
)
SELECT SUM(nn.acc) FROM nn WHERE nn.i + 1 = nn.l;
