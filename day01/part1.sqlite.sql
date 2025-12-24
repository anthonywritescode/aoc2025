CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE dials (n INT);
INSERT INTO dials
SELECT value FROM json_each((
    SELECT
        '[' ||
        REPLACE(REPLACE(REPLACE(s, 'L', '-'), 'R', ''), char(10), ',') ||
        ']'
    FROM input
));

SELECT COUNT(1) FROM (SELECT SUM(n) OVER (ORDER BY ROWID) AS n FROM dials)
WHERE (1000050 + n) % 100 = 0;
