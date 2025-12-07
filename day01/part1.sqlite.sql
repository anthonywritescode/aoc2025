CREATE TABLE input (s VARCHAR);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE positions (pos INT);
WITH RECURSIVE
    nn (pos, rest)
AS (
    SELECT 50, (SELECT s || char(10) FROM input)
    UNION ALL
    SELECT
        (
            nn.pos +
            REPLACE(
                REPLACE(
                    SUBSTR(nn.rest, 0, INSTR(nn.rest, char(10))),
                    'L',
                    '-'
                ),
                'R',
                ''
            )
            + 100 * 100
        ) % 100,
        SUBSTR(nn.rest, INSTR(nn.rest, char(10)) + 1)
    FROM nn
    WHERE nn.rest != ''
)
INSERT INTO positions
SELECT nn.pos FROM nn;

SELECT COUNT(1) FROM positions WHERE pos = 0;
