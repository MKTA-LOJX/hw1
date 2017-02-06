Do not execute this line...;


# Use the charity database
USE charity;


# Clean tables for the exercise
DROP TABLE periods;
DROP TABLE segments;


# We re going to divide the past in periods
# Create a table to store period information
CREATE TABLE periods (
  PeriodId INTEGER NOT NULL,
  FirstDay DATE NOT NULL,
  LastDay DATE NOT NULL,
  PRIMARY KEY (PeriodId)
)
ENGINE = MyISAM;


# Define 11 periods
# Period 0 = the most recent ("today")
INSERT INTO periods
VALUES ( 0, 20121101, 20131031),
       ( 1, 20111101, 20121031),
       ( 2, 20101101, 20111031),
       ( 3, 20091101, 20101031),
       ( 4, 20081101, 20091031),
       ( 5, 20071101, 20081031),
       ( 6, 20061101, 20071031),
       ( 7, 20051101, 20061031),
       ( 8, 20041101, 20051031),
       ( 9, 20031101, 20041031),
       (10, 20021101, 20031031);


# Create a segment table
# It will store to which segment each donor belonged
# in each period
CREATE TABLE segments (
  Sq INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  ContactId INTEGER UNSIGNED NOT NULL,
  PeriodId INTEGER NOT NULL,
  Segment VARCHAR(6),
  PRIMARY KEY (Sq),
  INDEX IdxContactId(ContactId),
  INDEX IdxPeriodId(PeriodId)
)
ENGINE = MyISAM;


# This will create a placeholder for all
# contact-by-period possible combinations
INSERT INTO segments (ContactId, PeriodId)
SELECT a.ContactId, p.PeriodId
FROM acts a,
     periods p
GROUP BY 1, 2;


# Create the AUTO segment
# You may require to remove the "safe mode" in MySQL Workbench
# Edit > Preferences > SQL Editor > Uncheck "Safe Updates"
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   acts a, periods p
   WHERE  (a.ActDate <= p.LastDay) AND
          (a.ActDate >= p.FirstDay) AND
          (a.ActType LIKE 'PA')) AS d
SET
  s.Segment = "AUTO"
WHERE
  (s.ContactId = d.ContactId) AND
  (s.PeriodId = d.PeriodId);


# Create the NEW segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM periods p,
        (SELECT ContactId, MIN(ActDate) AS FirstAct
         FROM acts
         GROUP BY 1) AS f
   WHERE (f.FirstAct <= p.LastDay) AND
         (f.FirstAct >= p.FirstDay)) AS d
SET
  s.Segment = "NEW"
WHERE
  (s.ContactId = d.ContactId) AND
  (s.PeriodId = d.PeriodId) AND
  (s.Segment IS NULL);


# Createthe BOTTOM/UP segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId, SUM(Amount) AS generosity
   FROM   acts a, periods p
   WHERE  (a.ActDate <= p.LastDay) AND
          (a.ActDate >= p.FirstDay) AND
          (a.ActType LIKE 'DO')
   GROUP BY 1, 2) AS d
SET
  s.Segment = IF(generosity < 100, "BOTTOM", "TOP")
WHERE
  (s.ContactId = d.ContactId) AND
  (s.PeriodId = d.PeriodId) AND
  (s.Segment IS NULL);


# Create the WARM segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   segments
   WHERE  (Segment LIKE "NEW")    OR
          (Segment LIKE "AUTO")   OR
          (Segment LIKE "BOTTOM") OR
          (Segment LIKE "TOP")) AS a
SET
  s.Segment = "WARM"
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = a.PeriodId - 1) AND
  (s.Segment IS NULL);


# Create the COLD segment
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   segments
   WHERE  Segment LIKE "WARM") AS a
SET
  s.Segment = "COLD"
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = a.PeriodId - 1) AND
  (s.Segment IS NULL);


# Create the LOST segment
# You need to apply this request multiple times!
UPDATE
  segments s,
  (SELECT ContactId, PeriodId
   FROM   segments
   WHERE  (Segment LIKE "COLD") OR
          (Segment LIKE "LOST")) AS a
SET
  s.Segment = "LOST"
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = a.PeriodId - 1) AND
  (s.Segment IS NULL);


# Count segment members per period
SELECT PeriodId, Segment, COUNT(*)
FROM segments
GROUP BY 1, 2
ORDER BY 2, 1 DESC;


# In which segments were donors last period,
# and where are they now?
SELECT old.Segment, new.Segment, COUNT(new.Segment)
FROM segments old,
     segments new
WHERE (old.ContactId = new.ContactId) AND
      (old.PeriodId = 1) AND
      (new.PeriodId = 0)
GROUP BY 1, 2
ORDER BY 1, 2;


# Report the financial contribution of each segment
SELECT
  s.Segment,
  COUNT(DISTINCT(s.ContactId)) AS 'numdonors',
  COUNT(a.Amount)              AS 'numdonations',
  CEILING(AVG(a.Amount))       AS 'avgamount',
  CEILING(SUM(a.Amount))       AS 'totalgenerosity'
FROM
  segments s,
  periods p,
  acts a
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = 0) AND
  (p.PeriodId = 0) AND
  (a.ActDate >= p.FirstDay) AND
  (a.ActDate <= p.LastDay)
GROUP BY 1
ORDER BY totalgenerosity DESC;


# Report the financial contribution in "period 0"
# (last 12 months) of each segment in period 1 (a year before)
SELECT
  s.Segment,
  COUNT(DISTINCT(s.ContactId)) AS 'numdonors',
  COUNT(a.Amount)              AS 'numdonations',
  CEILING(AVG(a.Amount))       AS 'avgamount',
  CEILING(SUM(a.Amount))       AS 'totalgenerosity'
FROM
  segments s,
  periods p,
  acts a
WHERE
  (s.ContactId = a.ContactId) AND
  (s.PeriodId = 1) AND
  (p.PeriodId = 0) AND
  (a.ActDate >= p.FirstDay) AND
  (a.ActDate <= p.LastDay)
GROUP BY 1
ORDER BY totalgenerosity DESC;
