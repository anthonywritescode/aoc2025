CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE input2 (ranges VARCHAR, nums VARCHAR);
INSERT INTO input2
SELECT
    SUBSTR(s, 0, INSTR(s, char(10) || char(10))),
    SUBSTR(s, INSTR(s, char(10) || char(10)) + 2)
FROM input;

CREATE TABLE ranges (s INT, e INT);
INSERT INTO ranges
SELECT value->>'[0]', value->>'[1]'
FROM json_each((
    SELECT '[[' || REPLACE(REPLACE(ranges, char(10), '],['), '-', ',') || ']]'
    FROM input2
))
ORDER BY value->>'[0]';

CREATE TABLE new_ranges (s INT, e INT);
WITH RECURSIVE nn (nrid, s, e) AS (
    SELECT ROWID + 1, s, e FROM ranges WHERE ROWID = 1
    UNION ALL
    SELECT
        nn.nrid + 1,
        CASE
            WHEN
                nn.s <= (SELECT ranges.s FROM ranges WHERE ROWID = nn.nrid) AND
                (SELECT ranges.s FROM ranges WHERE ROWID = nn.nrid) <= nn.e
            THEN nn.s
            ELSE (SELECT ranges.s FROM ranges WHERE ROWID = nn.nrid)
        END,
        CASE
            WHEN
                nn.s <= (SELECT ranges.s FROM ranges WHERE ROWID = nn.nrid) AND
                (SELECT ranges.s FROM ranges WHERE ROWID = nn.nrid) <= nn.e
            THEN
                MAX(nn.e, (SELECT ranges.e FROM ranges WHERE ROWID = nn.nrid))
            ELSE (SELECT ranges.e FROM ranges WHERE ROWID = nn.nrid)
        END
    FROM nn
    WHERE nn.nrid <= (SELECT MAX(ROWID) FROM ranges)
)
INSERT INTO new_ranges
SELECT nn.s, MAX(nn.e) FROM nn GROUP BY nn.s;

SELECT SUM(e - s + 1) FROM new_ranges;
