CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE lines (s VARCHAR);
INSERT INTO lines
SELECT value
FROM json_each((
    SELECT
        '["' || REPLACE(s, char(10), '","') || '"]'
    FROM input
));

CREATE TABLE splitme (d INT);
INSERT INTO splitme VALUES (1), (-1);

WITH RECURSIVE
    nn (total, rid, positions)
AS (
    SELECT 0, ROWID, json_array(INSTR(s, 'S'))
    FROM lines WHERE ROWID = 1
    UNION ALL
    SELECT
        nn.total + (
            SELECT COUNT(1) FROM json_each(nn.positions)
            WHERE SUBSTR(
                (SELECT s FROM lines WHERE ROWID = nn.rid),
                value,
                1
            ) = '^'
        ),
        nn.rid + 1,
        (
            SELECT json_group_array(newval) FROM (
                SELECT newval
                FROM (
                    SELECT value + coalesce(d, 0) AS newval
                    FROM json_each(nn.positions)
                    LEFT OUTER JOIN splitme ON
                        SUBSTR(
                            (SELECT s FROM lines WHERE ROWID = nn.rid),
                            value,
                            1
                        ) = '^'
                ) _
                -- XXX: I have no idea why I need this extra subquery? bug?
                GROUP BY newval
            ) _
        )
    FROM nn
    WHERE nn.rid <= (SELECT MAX(ROWID) FROM lines)
)
SELECT MAX(nn.total) FROM nn;
