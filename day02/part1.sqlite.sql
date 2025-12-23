CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE ranges (s INT, e INT);
INSERT INTO ranges
SELECT value->>0, value->>1
FROM json_each((
    SELECT '[[' || REPLACE(REPLACE(s, ',', '],['), '-', ',') || ']]'
    FROM input
));

SELECT SUM(n.value) FROM ranges, generate_series(s, e) n
WHERE
    SUBSTR(n.value, 1, LENGTH(n.value) / 2) =
    SUBSTR(n.value, LENGTH(n.value) / 2 + 1)
;
