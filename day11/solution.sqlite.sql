CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE edges (src TEXT, dest TEXT);
INSERT INTO edges
SELECT o.value->>0, i.value
FROM json_each((
    SELECT
        '[["' ||
        REPLACE(
            REPLACE(
                REPLACE(s, ': ', '",["'),
                ' ', '","'
            ),
            char(10), '"]],["'
        ) ||
        '"]]]'
    FROM input
)) o,
json_each(o.value->>1) i;

CREATE TABLE edgecounts (src TEXT, n INT);
INSERT INTO edgecounts SELECT src, COUNT(1) FROM edges GROUP BY src;

CREATE TABLE counts(src TEXT, dest TEXT, n INT);
WITH RECURSIVE nn (target, known) AS (
    SELECT 'out', json_array(json_array('out', 1))
    UNION ALL
    SELECT value, json_array(json_array(value, 1), json_array('out', 0))
    FROM json_each(json_array('fft', 'dac'))
    UNION ALL
    SELECT
        nn.target,
        (
            SELECT json_group_array(json(arr)) FROM (
                SELECT value AS arr FROM json_each(nn.known)
                UNION
                SELECT json_array(edges.src, SUM(known.n)) AS arr
                FROM edges
                INNER JOIN edgecounts ON edges.src = edgecounts.src
                INNER JOIN (
                    SELECT value->>0 AS dest, value->>1 AS n
                    FROM json_each(nn.known)
                ) known ON edges.dest = known.dest
                WHERE edges.src != nn.target
                GROUP BY edges.src
                HAVING MAX(edgecounts.n) = COUNT(1)
            )
        )
    FROM nn
    WHERE json_array_length(nn.known) != (SELECT COUNT(1) + 1 FROM edgecounts)
)
INSERT INTO counts
SELECT t.value->>0, target, t.value->>1
FROM nn, json_each(nn.known) t
WHERE json_array_length(nn.known) = (SELECT COUNT(1) + 1 FROM edgecounts);

SELECT 'part1';
SELECT n FROM counts WHERE src = 'you' AND dest = 'out';

SELECT 'part2';
SELECT (
    (SELECT n FROM counts WHERE src = 'svr' AND dest = 'dac') *
    (SELECT n FROM counts WHERE src = 'dac' AND dest = 'fft') *
    (SELECT n FROM counts WHERE src = 'fft' AND dest = 'out')
) + (
    (SELECT n FROM counts WHERE src = 'svr' AND dest = 'fft') *
    (SELECT n FROM counts WHERE src = 'fft' AND dest = 'dac') *
    (SELECT n FROM counts WHERE src = 'dac' AND dest = 'out')
);
