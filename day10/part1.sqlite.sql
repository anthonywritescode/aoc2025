CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE parsed (dest TEXT, buttons TEXT);
INSERT INTO parsed
SELECT
    value->>0,
    json_remove(value, '$[0]', '$[#-1]')
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

WITH RECURSIVE nn (paths, seen, dest, buttons) AS (
    SELECT
        '[[0,0]]', '[]',
        (
            SELECT SUM(
                (SUBSTR(dest, LENGTH(dest) - n.value, 1) = '#') <<
                (LENGTH(dest) - n.value - 1)
            )
            FROM generate_series(0, LENGTH(dest)) n
        ),
        (
            SELECT json_group_array((
                SELECT SUM(1 << i.value) FROM json_each(o.value) i
            ))
            FROM json_each(buttons) o
        )
    FROM parsed
    UNION ALL
    SELECT
        (
            SELECT json_group_array(json(arr)) FROM (
                SELECT value AS arr
                FROM json_each(json_remove(nn.paths, '$[0]'))
                UNION ALL
                SELECT json_array(
                    nn.paths->>0->>0 + 1,
                    -- xor, lol
                    (~(nn.paths->>0->>1 & value)) & (nn.paths->>0->>1 | value)
                )
                FROM json_each(nn.buttons)
                WHERE NOT EXISTS (
                    SELECT 1 FROM json_each(nn.seen)
                    WHERE value = nn.paths->>0->>1
                )
            )
        ),
        (
            SELECT json_group_array(n) FROM (
                SELECT value AS n
                FROM json_each(nn.seen)
                UNION
                SELECT nn.paths->>0->>1
            )
        ),
        nn.dest,
        nn.buttons
    FROM nn
    WHERE nn.paths->>0->>1 != nn.dest
)
SELECT SUM(nn.paths->>0->>0) FROM nn WHERE nn.paths->>0->>1 = nn.dest;
