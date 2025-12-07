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
));

CREATE TABLE nums (n INT);
INSERT INTO nums
SELECT value
FROM json_each((
    SELECT '[' || REPLACE(nums, char(10), ',') || ']'
    FROM input2
));

SELECT COUNT(DISTINCT nums.n)
FROM nums
INNER JOIN ranges ON ranges.s <= nums.n AND nums.n <= ranges.e;
