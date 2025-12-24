CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE ranges (s INT, e INT);
INSERT INTO ranges
SELECT value->>0, value->>1
FROM json_each((
    SELECT '[[' || REPLACE(REPLACE(s, ',', '],['), '-', ',') || ']]'
    FROM input
));

SELECT SUM(DISTINCT value) FROM (
    SELECT i.value
    FROM ranges, generate_series(s, e) i
    INNER JOIN generate_series(1, LENGTH(i.value) / 2) cs ON
        LENGTH(i.value) % cs.value = 0
    INNER JOIN generate_series(0, LENGTH(i.value) / cs.value - 1) c
    GROUP BY i.value, cs.value
    HAVING COUNT(DISTINCT SUBSTR(i.value, 1 + cs.value * c.value, cs.value)) = 1
);
