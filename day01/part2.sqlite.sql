CREATE TABLE input (s STRING);
INSERT INTO input VALUES (TRIM(readfile('input.txt'), char(10)));

CREATE TABLE positions (pos INT);
WITH RECURSIVE
    nn (pos, sign, rem, rest)
AS (
    SELECT 50, 1, 0, (SELECT s || char(10) FROM input)
    UNION ALL
    SELECT
        CASE nn.rem
            WHEN 0 THEN nn.pos
            ELSE (nn.pos + sign + 100) % 100
        END,
        CASE nn.rem
            WHEN 0 THEN
                CASE SUBSTR(nn.rest, 1, 1)
                    WHEN 'L' THEN -1
                    ELSE 1
                END
            ELSE nn.sign
        END,
        CASE nn.rem
            WHEN 0 THEN SUBSTR(nn.rest, 2, INSTR(nn.rest, char(10)) - 2)
            ELSE nn.rem - 1
        END,
        CASE nn.rem
            WHEN 0 THEN SUBSTR(nn.rest, INSTR(nn.rest, char(10)) + 1)
            ELSE nn.rest
        END
    FROM nn
    WHERE nn.rem != 0 OR nn.rest != ''
)
INSERT INTO positions
SELECT nn.pos FROM nn WHERE nn.rem != 0;

SELECT COUNT(1) FROM positions WHERE pos = 0;
