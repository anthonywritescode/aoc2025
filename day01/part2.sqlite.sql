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

CREATE TABLE landed (n INT);
INSERT INTO landed VALUES (50);
INSERT INTO landed
SELECT (1000050 + n) % 100
FROM (SELECT SUM(n) OVER (ORDER BY ROWID) AS n FROM dials);

SELECT SUM(
    abs(dials.n) / 100 +
    ((landed.n + (dials.n % 100)) >= 100) +
    (landed.n > 0 AND ((landed.n + (dials.n % 100)) <= 0))
)
FROM landed, dials WHERE landed.ROWID = dials.ROWID;
