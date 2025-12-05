CREATE TABLE input (s STRING);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE ranges (s INT, e INT);
INSERT INTO ranges
SELECT value->>'[0]', value->>'[1]'
FROM json_each((
    SELECT
        '[[' ||
        REPLACE(
            REPLACE(
                SUBSTR(s, 0, INSTR(s, char(10) || char(10))),
                char(10),
                '],['
            ),
            '-',
            ','
        ) ||
        ']]'
    FROM input
));

CREATE TABLE nums (n INT);
INSERT INTO nums
SELECT value
FROM json_each((
    SELECT
        '[' ||
        REPLACE(
            SUBSTR(s, INSTR(s, char(10) || char(10)) + 2),
            char(10),
            ','
        ) ||
        ']'
    FROM input
));

SELECT COUNT(DISTINCT nums.n)
FROM nums
INNER JOIN ranges ON ranges.s <= nums.n AND nums.n <= ranges.e;
