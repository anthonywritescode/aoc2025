CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE parts (s TEXT);
INSERT INTO parts
SELECT value
FROM json_each((
    SELECT
        '["' ||
        REPLACE(REPLACE(s, char(10) || char(10), '","'), char(10), '\n') ||
        '"]'
    FROM input
));

CREATE TABLE rows (w INT, h INT, n_shapes INT);
INSERT INTO rows
SELECT
    o.value->>0, o.value->>1,
    (SELECT SUM(i.value) FROM json_each(o.value->>2) i)
FROM json_each((
    SELECT
        '[[' ||
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        s,
                        ': ', ',['
                    ),
                    'x', ','
                ),
                ' ', ','
            ),
            char(10), ']],['
        ) ||
        ']]]'
    FROM parts
    WHERE ROWID = 7
)) o;

SELECT COUNT(1) FROM rows WHERE w / 3 * h / 3 >= n_shapes;
