CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE edges (src TEXT, dest TEXT);
INSERT INTO edges
SELECT o.value->>'[0]', i.value
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
json_each(o.value->>'[1]') i;

CREATE TABLE counts(src TEXT, dest TEXT, n INT);
WITH RECURSIVE nn (todo, known) AS (
    SELECT
        (
            SELECT json_group_array(DISTINCT json_array(src, 'out'))
            FROM edges
        ),
        json_array(json_array('out', 'out', 1))
    UNION ALL
    SELECT
        (
            SELECT json_group_array(DISTINCT json_array(src, value))
            FROM edges
            WHERE src != value
        ),
        json_array(json_array(value, value, 1), json_array('out', value, 0))
        FROM json_each(json_array('fft', 'dac'))
    UNION ALL
    SELECT
        (
            SELECT json_group_array(json(t.value)) FROM json_each(nn.todo) t
            WHERE
                (
                    SELECT COUNT(1) FROM edges
                    WHERE edges.src = t.value->>'[0]'
                ) != (
                    SELECT COUNT(1)
                    FROM edges, json_each(nn.known) k
                    WHERE
                        edges.src = t.value->>'[0]' AND
                        edges.dest = k.value->>'[0]' AND
                        k.value->>'[1]' = t.value->>'[1]'
                )
        ),
        (
            SELECT json_group_array(json(arr)) FROM (
                SELECT value AS arr FROM json_each(nn.known)
                UNION ALL
                SELECT json_insert(
                    t.value, '$[#]',
                    (
                        SELECT SUM(k.value->>'[2]')
                        FROM edges, json_each(nn.known) k
                        WHERE
                            edges.src = t.value->>'[0]' AND
                            edges.dest = k.value->>'[0]' AND
                            k.value->>'[1]' = t.value->>'[1]'
                    )
                ) AS arr
                FROM json_each(nn.todo) t
                WHERE
                    (
                        SELECT COUNT(1) FROM edges
                        WHERE edges.src = t.value->>'[0]'
                    ) = (
                        SELECT COUNT(1)
                        FROM edges, json_each(nn.known) k
                        WHERE
                            edges.src = t.value->>'[0]' AND
                            edges.dest = k.value->>'[0]' AND
                            k.value->>'[1]' = t.value->>'[1]'
                    )
            )
        )
    FROM nn
    WHERE nn.todo != '[]'
)
INSERT INTO counts
SELECT t.value->>'[0]', t.value->>'[1]', t.value->>'[2]'
FROM nn, json_each(nn.known) t
WHERE nn.todo = '[]' ;

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
