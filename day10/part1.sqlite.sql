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

WITH RECURSIVE nn (len, n, paths, seen, dest, buttons) AS (
    SELECT
        NULL, NULL, '[0,0]', '_',
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
        CASE
            WHEN nn.len IS NULL THEN
                SUBSTR(nn.paths, 1, INSTR(nn.paths, ']'))->>0
            ELSE NULL
        END,
        CASE
            WHEN nn.len IS NULL THEN
                SUBSTR(nn.paths, 1, INSTR(nn.paths, ']'))->>1
            ELSE NULL
        END,
        CASE
            WHEN nn.len IS NULL THEN
                SUBSTR(nn.paths, INSTR(nn.paths, ']') + 1)
            WHEN nn.seen LIKE '%_' || nn.n || '_%' THEN nn.paths
            ELSE
                nn.paths || (
                    SELECT group_concat(
                        json_array(
                            nn.len + 1,
                            -- xor, lol
                            (~(nn.n & value)) & (nn.n | value)
                        ),
                        ''
                    )
                    FROM json_each(nn.buttons)
                )
        END,
        CASE
            WHEN nn.len IS NULL THEN nn.seen
            WHEN nn.seen LIKE '%_' || nn.n || '_%' THEN nn.seen
            ELSE nn.seen || nn.n || '_'
        END,
        nn.dest,
        nn.buttons
    FROM nn
    WHERE nn.n is null or nn.n != nn.dest
)
SELECT SUM(nn.len) FROM nn WHERE nn.n = nn.dest;
