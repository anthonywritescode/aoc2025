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
    nn (rid, positions)
AS (
    SELECT ROWID, json_array(json_array(INSTR(s, 'S'), 1))
    FROM lines WHERE ROWID = 1
    UNION ALL
    SELECT
        nn.rid + 1,
        (
            SELECT json_group_array(json_array(k, v)) FROM (
                SELECT k, SUM(v) AS v
                FROM (
                    SELECT
                        value->>'[0]' + coalesce(d, 0) AS k,
                        value->>'[1]' AS v
                    FROM json_each(nn.positions)
                    LEFT OUTER JOIN splitme ON
                        SUBSTR(
                            (SELECT s FROM lines WHERE ROWID = nn.rid),
                            value->>'[0]',
                            1
                        ) = '^'
                ) _
                GROUP BY k
                ORDER BY k
            ) _
        )
    FROM nn
    WHERE nn.rid <= (SELECT MAX(ROWID) FROM lines)
)
SELECT SUM(value->>'[1]') FROM json_each((
    SELECT positions FROM nn
    WHERE nn.rid = (SELECT MAX(ROWID) FROM lines)
));
