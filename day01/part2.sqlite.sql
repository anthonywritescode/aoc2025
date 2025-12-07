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

WITH RECURSIVE
    nn (total, pos, rid)
AS (
    SELECT 0, 50, 1
    UNION ALL
    SELECT
        (
            nn.total +
            ABS((SELECT n FROM dials WHERE ROWID = nn.rid)) / 100 +
            (
                nn.pos > 0 AND
                nn.pos + (SELECT n FROM dials WHERE ROWID = nn.rid) % 100 <= 0
            ) +
            (nn.pos + (SELECT n FROM dials WHERE ROWID = nn.rid) % 100 >= 100)
        ),
        (nn.pos + (SELECT n FROM dials WHERE ROWID = nn.rid) + 1000) % 100,
        nn.rid + 1
    FROM nn
    WHERE nn.rid <= (SELECT MAX(ROWID) FROM dials)
)
SELECT MAX(total) FROM nn;
