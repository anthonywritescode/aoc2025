CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE parsed (buttons TEXT, dest TEXT);
INSERT INTO parsed
SELECT
    json_remove(value, '$[0]', '$[#-1]'),
    value->>'$[#-1]'
FROM json_each((
    SELECT
        '[' ||
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    input.s,
                                    '[', '["'
                                ),
                                ']', '",'
                            ),
                            "(", "["
                        ),
                        ")", "],"
                    ),
                    "{", "["
                ),
                "}", "]"
            ),
            char(10), "],"
        ) || ']]'
    FROM input
));


CREATE TABLE row1(rid INT, r TEXT);
INSERT INTO row1
SELECT
    ROWID,
    (
        SELECT json_insert(
            (
                SELECT json_group_array(json_array_length(b.value))
                FROM json_each(parsed.buttons) b
            ),
            '$[#]',
            (SELECT SUM(value) FROM json_each(parsed.dest))
        )
    )
FROM parsed;

CREATE TABLE bypos(rid INT, r TEXT);
INSERT INTO bypos
SELECT
    parsed.ROWID,
    json_insert(
        (
            SELECT json_group_array(
                (
                    SELECT COUNT(1)
                    FROM json_each(json(b.value)) i
                    WHERE i.value = o.key+0
                )
            )
            FROM json_each(parsed.buttons) b
        ),
        '$[#]',
        o.value
    )
FROM parsed, json_each(parsed.dest) o;

CREATE TABLE matrices (m TEXT);
INSERT INTO matrices
SELECT json_group_array(json(r)) FROM (
    SELECT row1.rid, row1.r FROM row1
    UNION ALL
    SELECT bypos.rid, bypos.r FROM bypos
)
GROUP BY rid;

CREATE TABLE with_bounds(m TEXT, bounds TEXT);
INSERT INTO with_bounds
SELECT
  matrices.m,
  json_group_array((
    SELECT MIN(j.value->>'$[#-1]' / j.value->>s.value)
    FROM json_each(m) j
    WHERE j.value->>s.value != 0
))
FROM matrices, generate_series(0, json_array_length(m->>0) - 2) s
GROUP BY matrices.ROWID;

CREATE TABLE fac (n INT);
INSERT INTO fac
SELECT value FROM generate_series(1, 60)
ORDER BY value DESC;

CREATE TABLE reduced (m TEXT, bounds TEXT);
WITH RECURSIVE nn (i_max, h, k, m, n, mut, bounds) AS (
    SELECT
        NULL,
        0, 0, json_array_length(m), json_array_length(m->>0), m, bounds
    FROM with_bounds
    UNION ALL
    SELECT
        CASE
            WHEN nn.i_max IS NULL THEN (
                SELECT MIN(o.key) FROM json_each(nn.mut) o
                WHERE
                    o.key >= nn.h AND
                    o.value->>nn.k != 0 AND
                    o.value->>nn.k >= (
                        SELECT MAX(i.value->>nn.k) FROM json_each(nn.mut) i
                        WHERE i.key >= nn.h
                    )
            )
            ELSE NULL
        END,
        CASE WHEN nn.i_max IS NULL THEN nn.h ELSE nn.h + 1 END,
        CASE
            WHEN nn.i_max IS NULL AND EXISTS (
                SELECT 1 FROM json_each(nn.mut)
                WHERE key >= nn.h AND value->>nn.k != 0
            ) THEN nn.k
            ELSE nn.k + 1
        END,
        nn.m,
        nn.n,
        CASE
            WHEN nn.i_max IS NULL THEN nn.mut
            ELSE (
                SELECT json_group_array(json(arr)) FROM (
                    SELECT
                        CASE
                            WHEN o.key <= nn.h THEN o.value
                            ELSE (
                                SELECT json_group_array(v) FROM (
                                    SELECT (
                                        i.value * (den / gcf) -
                                        nn.mut->>nn.i_max->>i.key * (num / gcf)
                                    ) AS v
                                    FROM json_each(o.value) i
                                    INNER JOIN (
                                        SELECT den, num,
                                            (
                                                SELECT MAX(n) FROM fac
                                                WHERE
                                                    den % n = 0 and
                                                    num % n = 0
                                            ) AS gcf
                                        FROM (
                                            SELECT
                                                nn.mut->nn.i_max->>nn.k AS den,
                                                o.value->>nn.k as num
                                        )
                                    )
                                )
                            )
                        END AS arr
                    FROM json_each(
                        json_set(
                            nn.mut,
                            format('$[%d]', nn.h), nn.mut->>nn.i_max,
                            format('$[%d]', nn.i_max), nn.mut->>nn.h
                        )
                    ) o
                )
            )
        END,
        nn.bounds
    FROM nn
    WHERE nn.h < nn.m AND nn.k < nn.n
)
INSERT INTO reduced
SELECT nn.mut, nn.bounds FROM nn WHERE nn.h >= nn.m OR nn.k >= nn.n;

-- if this ever produces rows then the ints got too big
SELECT * FROM reduced WHERE m LIKE '%e%';

CREATE TABLE answers (rid INT, total INT);
WITH RECURSIVE nn (selected, total, rid, m, bounds) AS (
    SELECT NULL, 0, ROWID, m, bounds FROM reduced
    UNION ALL
    SELECT
        CASE
            WHEN nn.selected IS NULL THEN (
                -- exact solutions
                SELECT json_array(
                    var,
                    CASE
                        WHEN n % val != 0 THEN -1
                        WHEN n / val < 0 THEN -1
                        ELSE n / val
                    END,
                    CASE
                        WHEN n % val != 0 THEN -2
                        WHEN n / val < 0 THEN -2
                        ELSE n / val
                    END
                )
                FROM (
                    SELECT
                        o.value->>'[#-1]' AS n,
                        i.key AS var,
                        i.value AS val
                    FROM json_each(nn.m) o
                    INNER JOIN json_each(json_remove(o.value, '$[#-1]')) i
                    WHERE i.value != 0
                    GROUP BY o.key
                    HAVING COUNT(1) = 1
                    LIMIT 1
                )
                UNION ALL
                -- illegal: const and sign differ
                SELECT '[0,-1,-2]'
                FROM json_each(nn.m) o
                INNER JOIN json_each(json_remove(o.value, '$[#-1]')) i
                WHERE i.value != 0
                GROUP BY o.key
                HAVING
                    (o.value->>'[#-1]' < 0 AND MIN(i.value) > 0) OR
                    (o.value->>'[#-1]' > 0 AND MAX(i.value) < 0)
                UNION ALL
                -- inexact solutions
                SELECT json_array(k, 0, bounds->>k) FROM (
                    SELECT i.key AS k
                    FROM json_each(nn.m) o
                    INNER JOIN json_each(json_remove(o.value, '$[#-1]')) i
                    WHERE i.value != 0
                    ORDER BY i.key DESC
                    LIMIT 1
                )
            )
            ELSE NULL
        END,
        nn.total + v.value,
        nn.rid,
        CASE
            WHEN nn.selected IS NULL THEN nn.m
            ELSE (
                SELECT json_group_array(json(arr)) FROM (
                    SELECT json_replace(
                        value,
                        format('$[%d]', nn.selected->>0),
                        0,
                        '$[#-1]',
                        value->>'$[#-1]' - value->>(nn.selected->>0) * v.value
                    ) AS arr
                    FROM json_each(nn.m)
                )
                WHERE EXISTS (SELECT 1 FROM json_each(arr) WHERE value != 0)
            )
        END,
        nn.bounds
    FROM nn
    INNER JOIN generate_series(
        COALESCE(nn.selected, '[0,0,0]')->>1,
        COALESCE(nn.selected, '[0,0,0]')->>2
    ) v
    WHERE nn.m != '[]'
)
INSERT INTO answers
SELECT nn.rid, MIN(nn.total) FROM nn WHERE nn.m = '[]' GROUP BY nn.rid;

SELECT SUM(total) FROM answers;
