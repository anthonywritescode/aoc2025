CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE lines (s VARCHAR);
INSERT INTO lines
SELECT value
FROM json_each((
    SELECT
        '["' || REPLACE(s, char(10), ' ","') || ' "]'
    FROM input
));

CREATE TABLE opstr (s VARCHAR);
INSERT INTO opstr
SELECT s || '+*' FROM lines
ORDER BY ROWID DESC
LIMIT 1;

DELETE FROM lines
ORDER BY ROWID DESC
LIMIT 1;

CREATE TABLE ops (op VARCHAR, s INT, l INT);
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

CREATE TABLE orig_numstrs (oprid INT, s VARCHAR);
INSERT INTO orig_numstrs
SELECT ops.ROWID, SUBSTR(lines.s, ops.s, ops.l - 1)
FROM ops, lines;

CREATE TABLE numstrs (oprid INT, s VARCHAR);
INSERT INTO numstrs
SELECT rid, group_concat(c, '') FROM (
    SELECT
        ops.ROWID AS rid,
        i.value AS i,
        SUBSTR(orig_numstrs.s, i.value, 1) AS c
    FROM ops, generate_series(1, ops.l - 1) AS i
    INNER JOIN orig_numstrs ON ops.ROWID = orig_numstrs.oprid
    ORDER BY orig_numstrs.ROWID
) _
GROUP BY rid, i;

WITH RECURSIVE
    nn (acc, op, arr)
AS (
    SELECT
        (CASE ops.op WHEN '+' THEN 0 WHEN '*' THEN 1 ELSE '???' END),
        ops.op,
        json_group_array(numstrs.s)
    FROM ops
    INNER JOIN numstrs ON numstrs.oprid = ops.ROWID
    GROUP BY ops.ROWID

    UNION ALL

    SELECT
        CASE nn.op
            WHEN '+' THEN nn.acc + nn.arr->>'[0]'
            WHEN '*' THEN nn.acc * nn.arr->>'[0]'
            ELSE '???'
        END,
        nn.op,
        json_remove(nn.arr, '$[0]')
    FROM nn
    WHERE nn.arr != '[]'
)
SELECT SUM(nn.acc) FROM nn WHERE nn.arr = '[]';
