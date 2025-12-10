CREATE TABLE input (n INT, s VARCHAR);
INSERT INTO input VALUES (1000, TRIM(readfile('input.txt'), char(10)));

CREATE TABLE points (x INT, y INT);
INSERT INTO points
SELECT value->>'[0]', value->>'[1]'
FROM json_each((
    SELECT '[[' || REPLACE(s, char(10), '],[') || ']]'
    FROM input
));

CREATE TABLE d4 (d TEXT, dx INT, dy INT);
INSERT INTO d4 (ROWID, d, dx, dy)
VALUES
    (0, 'UP', 0, -1),
    (1, 'RIGHT', 1, 0),
    (2, 'DOWN', 0, 1),
    (3, 'LEFT', -1, 0);

CREATE TABLE directions (d TEXT);
INSERT INTO directions
SELECT
    CASE
        WHEN p1.x = p2.x THEN
            CASE WHEN p1.y < p2.y THEN 'DOWN' ELSE 'UP' END
        ELSE
            CASE WHEN p1.x < p2.x THEN 'RIGHT' ELSE 'LEFT' END
    END
FROM points p1, points p2
WHERE p1.ROWID = 1 AND p2.ROWID = 2;

CREATE TABLE vertical (x INT, y1 INT, y2 INT);
CREATE TABLE horizontal (y INT, x1 INT, x2 INT);
CREATE TABLE outside_cw (x INT, y INT);
CREATE TABLE outside_ccw (x INT, y INT);

CREATE TABLE cw_count (cw INT, ccw INT);
INSERT INTO cw_count VALUES (0, 0);

CREATE TABLE points2 (x INT, y INT);
INSERT INTO points2 SELECT * FROM points WHERE ROWID = 2;
CREATE TEMPORARY TRIGGER ttrig
AFTER INSERT ON points2 BEGIN

    INSERT INTO directions
    SELECT
        CASE
            WHEN p1.x = NEW.x THEN
                CASE WHEN p1.y < NEW.y THEN 'DOWN' ELSE 'UP' END
            ELSE
                CASE WHEN p1.x < NEW.x THEN 'RIGHT' ELSE 'LEFT' END
        END
    FROM points2 p1
    WHERE p1.ROWID = NEW.ROWID - 1;

    INSERT INTO vertical
    SELECT x, MIN(p1.y, NEW.y), MAX(p1.y, NEW.y)
    FROM points2 p1
    WHERE p1.ROWID = NEW.ROWID - 1 AND p1.x = NEW.x;

    INSERT INTO horizontal
    SELECT y, MIN(p1.x, NEW.x), MAX(p1.x, NEW.x)
    FROM points2 p1
    WHERE p1.ROWID = NEW.ROWID - 1 AND p1.y = NEW.y;

    UPDATE cw_count
    SET
        cw = cw + ((d1_d.ROWID + 1) % 4 = d2_d.ROWID),
        ccw = ccw + ((d1_d.ROWID + 3) % 4 == d2_d.ROWID)
    FROM directions d1, directions d2
    INNER JOIN d4 d1_d ON d1.d = d1_d.d
    INNER JOIN d4 d2_d ON d2.d = d2_d.d
    WHERE
        d1.ROWID = (SELECT MAX(ROWID) - 1 FROM directions) AND
        d2.ROWID = (SELECT MAX(ROWID) FROM directions);

    INSERT INTO outside_cw
    SELECT
        -- x
        CASE
            WHEN (d1_d.ROWID + 1) % 4 = d2_d.ROWID THEN
                p1.x + d1_d.dx + -1 * d2_d.dx
                -- outside.append(prev_d.apply(*d.opposite.apply(*prev_p)))
            ELSE
                p1.x + -1 * d1_d.dx + d2_d.dx
                -- outside.append(prev_d.opposite.apply(*d.apply(*prev_p)))
        END,
        -- y
        CASE
            WHEN (d1_d.ROWID + 1) % 4 = d2_d.ROWID THEN
                p1.y + d1_d.dy + -1 * d2_d.dy
                -- outside.append(prev_d.apply(*d.opposite.apply(*prev_p)))
            ELSE
                p1.y + -1 * d1_d.dy + d2_d.dy
                -- outside.append(prev_d.opposite.apply(*d.apply(*prev_p)))
        END
    FROM directions d1, directions d2, points2 p1
    INNER JOIN d4 d1_d ON d1.d = d1_d.d
    INNER JOIN d4 d2_d ON d2.d = d2_d.d
    WHERE
        p1.ROWID = NEW.ROWID -1 AND
        d1.ROWID = (SELECT MAX(ROWID) - 1 FROM directions) AND
        d2.ROWID = (SELECT MAX(ROWID) FROM directions);

    INSERT INTO outside_ccw
    SELECT
        -- x
        CASE
            WHEN (d1_d.ROWID + 1) % 4 = d2_d.ROWID THEN
                p1.x + -1 * d1_d.dx + d2_d.dx
            ELSE
                p1.x + d1_d.dx + -1 * d2_d.dx
        END,
        -- y
        CASE
            WHEN (d1_d.ROWID + 1) % 4 = d2_d.ROWID THEN
                p1.y + -1 * d1_d.dy + d2_d.dy
            ELSE
                p1.y + d1_d.dy + -1 * d2_d.dy
        END
    FROM directions d1, directions d2, points2 p1
    INNER JOIN d4 d1_d ON d1.d = d1_d.d
    INNER JOIN d4 d2_d ON d2.d = d2_d.d
    WHERE
        p1.ROWID = NEW.ROWID -1 AND
        d1.ROWID = (SELECT MAX(ROWID) - 1 FROM directions) AND
        d2.ROWID = (SELECT MAX(ROWID) FROM directions);

END;
INSERT INTO points2 SELECT * FROM points WHERE ROWID > 2;
INSERT INTO points2 SELECT * FROM points WHERE ROWID <= 2;

CREATE TABLE outside (x INT, y INT);
INSERT INTO outside
SELECT * FROM outside_cw WHERE (SELECT cw > ccw FROM cw_count)
UNION
SELECT * FROM outside_ccw WHERE (SELECT cw < ccw FROM cw_count);

SELECT MAX((ABS(p1.x - p2.x) + 1) * (ABS(p1.y - p2.y) + 1))
FROM points p1, points p2
WHERE
    -- points[i + 1:]
    p2.ROWID > p1.ROWID AND
    NOT EXISTS(
        SELECT 1 FROM points p3
        WHERE
            -- p3 is p1 or p3 is p2
            p3.ROWID != p1.ROWID AND p3.ROWID != p2.ROWID AND
            -- _contains(p1, p2, p3)
            MIN(p1.x, p2.x) < p3.x AND p3.x < MAX(p1.x, p2.x) AND
            MIN(p1.y, p2.y) < p3.y AND p3.y < MAX(p1.y, p2.y)
    ) AND
    NOT EXISTS(
        SELECT 1 FROM outside
        WHERE
            MIN(p1.x, p2.x) < outside.x AND outside.x < MAX(p1.x, p2.x) AND
            MIN(p1.y, p2.y) < outside.y AND outside.y < MAX(p1.y, p2.y)
    ) AND
    NOT EXISTS(
        SELECT 1 FROM vertical v
        WHERE
            (
                MIN(p1.x, p2.x) < v.x AND v.x < MAX(p1.x, p2.x) AND
                v.y1 < p2.y AND p2.y < v.y2
            ) OR (
                MIN(p1.x, p2.x) < v.x AND v.x < MAX(p1.x, p2.x) AND
                v.y1 < p1.y AND p1.y < v.y2
            )
    ) AND
    NOT EXISTS (
        SELECT 1 FROM horizontal h
        WHERE
            (
                h.x1 < p1.x AND p1.x < h.x2 AND
                MIN(p1.y, p2.y) < h.y AND h.y < MAX(p1.y, p2.y)
            ) OR (
                h.x1 < p2.x AND p2.x < h.x2 AND
                MIN(p1.y, p2.y) < h.y AND h.y < MAX(p1.y, p2.y)
            )
    )
;
