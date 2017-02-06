Do not execute this line...;


# Find where data files are stored locally
SHOW VARIABLES LIKE 'datadir';


# Create an empty database
CREATE DATABASE charity;


# Show the existing databases
SHOW DATABASES;


# Use a specific database
USE charity;


# Create contact table
# Here, Sq and ContactId “should” be redundant
CREATE TABLE contacts (
  Sq        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  ContactId INT UNSIGNED NOT NULL,
  Prefix    CHAR(6),
  FirstName CHAR(32),
  ZipCode   CHAR(5),
  Status    TINYINT UNSIGNED DEFAULT '0',
  PRIMARY KEY (Sq),
  KEY IdxContactId (ContactId)
  )
ENGINE = MyISAM;


# Create act table (donations)
CREATE TABLE acts (
  Sq          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  ContactId   INT UNSIGNED NOT NULL,
  Amount      FLOAT DEFAULT '0',
  ActDate     DATE,
  ActType     CHAR(2),
  PaymentType CHAR(2),
  MessageId   CHAR(10),
  PRIMARY KEY (Sq),
  KEY IdxContactId (ContactId),
  KEY IdxActDate   (ActDate))
ENGINE = MyISAM;


# Create action table (solicitations)
CREATE TABLE actions (
  Sq         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  ContactId  INT UNSIGNED NOT NULL,
  MessageId  CHAR(10),
  ActionDate DATE,
  PRIMARY KEY (Sq),
  KEY IdxContactId (ContactId),
  KEY IdxMessageId (MessageId))
ENGINE = MyISAM;


# Load contacts from text file
LOAD DATA INFILE 'contacts.txt' INTO TABLE contacts;


# Load acts from text file
LOAD DATA INFILE 'acts.txt' INTO TABLE acts;


# Load actions from text file
LOAD DATA INFILE 'actions.txt' INTO TABLE actions;


# Insert a row in a table
# Note that AUTO_INCREMENT fields... auto increment
# Field names are optional if you set a value for all
# Watch out for the NOT NULL fields
INSERT INTO contacts
   (ContactId, Prefix, FirstName, ZipCode)
VALUES (249280, "MR", "ARNAUD", 95000);


# Update a row
UPDATE contacts
SET Prefix = "DR"
WHERE ContactId = 249280;


# Delete a row
DELETE FROM contacts
WHERE ContactId = 249280;


# Select (list) all data from a table
SELECT * FROM contacts;


# Select all data from a table, and save into file
# SELECT * INTO OUTFILE 'contacts.txt' FROM contacts;


# Select specific fields from a table
SELECT FirstName, ZipCode FROM contacts;


# Select aggregate functions
SELECT MIN(ActDate),
       MAX(ActDate),
       COUNT(*),
       SUM(Amount),
       AVG(Amount)
FROM acts;


# Rename output (alias)
SELECT MIN(ActDate) AS firstgift,
       MAX(ActDate) AS lastgift,
       COUNT(*)     AS numgifts,
       SUM(Amount)  AS sumgifts,
       AVG(Amount)  AS averagegift
FROM acts;


# Sum of donations, per year
SELECT YEAR(ActDate), SUM(Amount)
FROM acts
GROUP BY 1
ORDER BY 1;


# This is equivalent, with an alias, and
# listed in decreasing order
SELECT YEAR(ActDate) AS year, SUM(Amount)
FROM acts
GROUP BY year
ORDER BY year DESC;


# List first names in decreasing order of occurrence
SELECT FirstName, COUNT(*)
FROM contacts
GROUP BY 1
ORDER BY 2 DESC;


# List the ten most common first names
SELECT FirstName, COUNT(*)
FROM contacts
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


# List donors and key marketing indicators
# by decreasing order of average donation
SELECT ContactId,
       AVG(Amount) AS averageamount,
       COUNT(*)    AS numdonations,
       SUM(Amount) AS totalgenerosity
FROM acts
GROUP BY ContactId
ORDER BY averageamount DESC;


# List gifts of 1000 EUR or more
SELECT *
FROM acts
WHERE Amount >= 1000;


# List donors who made gifts of 1000 EUR or more
SELECT ContactId
FROM acts
WHERE Amount >= 1000
ORDER BY ContactId;


# Same, but exclude duplicates
SELECT DISTINCT(ContactId)
FROM acts
WHERE Amount >= 1000
ORDER BY ContactId;


# List the ten most common first names,
# but exclude NULL values
SELECT FirstName, COUNT(*)
FROM contacts
WHERE FirstName IS NOT NULL
GROUP BY FirstName
ORDER BY 2 DESC
LIMIT 10;


# This is equivalent...
# COUNT(*)     = number of rows
# COUNT(field) = number of non-null values
SELECT FirstName, COUNT(FirstName)
FROM contacts
GROUP BY FirstName
ORDER BY 2 DESC
LIMIT 10;


# List contact information of donors who made
# single donations of 1000 EUR or more
# But you will have duplicates !!!
SELECT contacts.ContactId,
       contacts.FirstName,
       contacts.Prefix,
       contacts.ZipCode
FROM contacts
JOIN acts
ON contacts.ContactId = acts.ContactId
WHERE acts.Amount >= 1000;


# List contact information of donors who made
# single donations of 1000 EUR or more
# GROUP BY will remove duplicates, BUT it won t work
SELECT contacts.ContactId,
       contacts.FirstName,
       contacts.Prefix,
       contacts.ZipCode
FROM contacts
JOIN acts
ON contacts.ContactId = acts.ContactId
WHERE acts.Amount >= 1000
GROUP BY contacts.ContactId;


# This is correct
SELECT contacts.ContactId,
       ANY_VALUE(contacts.FirstName),
       ANY_VALUE(contacts.Prefix),
       ANY_VALUE(contacts.ZipCode)
FROM contacts
JOIN acts
ON contacts.ContactId = acts.ContactId
WHERE acts.Amount >= 1000
GROUP BY contacts.ContactId;


# This is equivalent, less verbose, no ambiguity
SELECT c.ContactId,
       ANY_VALUE(c.FirstName),
       ANY_VALUE(c.Prefix),
       ANY_VALUE(c.ZipCode)
FROM contacts AS c
JOIN acts AS a
ON c.ContactId = a.ContactId
WHERE a.Amount >= 1000
GROUP BY c.ContactId;


# This is also equivalent, with a WHERE clause
SELECT c.ContactId,
       ANY_VALUE(c.FirstName),
       ANY_VALUE(c.Prefix),
       ANY_VALUE(c.ZipCode)
FROM contacts AS c,
     acts AS a
WHERE (c.ContactId = a.ContactId)
  AND (a.Amount >= 1000)
GROUP BY c.ContactId;


# List the most generous first names
SELECT c.FirstName,
       FLOOR(AVG(a.Amount)) AS averagegift
FROM acts AS a
JOIN contacts AS c
ON a.ContactId = c.ContactId
GROUP BY 1
ORDER BY 2 DESC;


# --- SESSION 1 STOPS HERE ---


# List the most generous first names, but only
# if there are enough observations
# HAVING is “like” WHERE, but used after grouping
SELECT c.FirstName,
       FLOOR(AVG(a.Amount)) AS averagegift
FROM acts AS a
JOIN contacts AS c
ON a.ContactId = c.ContactId
GROUP BY 1
HAVING COUNT(c.FirstName) >= 10
ORDER BY 2 DESC;


# Compute key marketing indicators for each donor
# Since we are computing aggregate functions,
# do not forget GROUP BY
SELECT c.ContactId            AS id,
       LEFT(c.ZipCode, 2)     AS department,
       MIN(a.ActDate)         AS firstgift,
       MAX(a.ActDate)         AS recency,
       CEILING(AVG(a.Amount)) AS avgamount,
       COUNT(a.Amount)        AS frequency
FROM contacts AS c
JOIN acts AS a
ON c.ContactId = a.ContactId
GROUP BY c.ContactId;


# Count the number of donors by frequency
# of regular donations (“DO”), excluding
# automatic deductions (“PA”)

# Step 1, compute frequencies
SELECT ContactId, COUNT(*) AS frequency
FROM acts WHERE ActType LIKE "DO"
GROUP BY ContactId;

# Step 2, group donors by frequencies
# Note that every derived table needs its own alias
SELECT COUNT(frequency) AS counter, frequency
FROM (SELECT ContactId, COUNT(*) AS frequency
      FROM acts WHERE ActType LIKE "DO"
      GROUP BY ContactId) AS q
GROUP BY frequency
ORDER BY frequency;


# Report average frequency and donation amount
# by prefix

# Step 1
SELECT ContactId,
       COUNT(*) AS frequency,
       AVG(Amount) AS avgamount
FROM acts WHERE ActType LIKE "DO"
GROUP BY ContactId;

# Step 2
# Note the difference between computing
# AVG(amount) and AVG(avgamount)
SELECT Prefix,
       AVG(frequency),
       AVG(avgamount),
       COUNT(*)
FROM contacts c
JOIN (SELECT ContactId,
             COUNT(*) AS frequency,
             AVG(Amount) AS avgamount
      FROM acts WHERE ActType LIKE "DO"
      GROUP BY ContactId) AS q
ON c.ContactId = q.ContactId
GROUP BY 1
ORDER BY 2 DESC;


# Compute number of regular donations and number
# of automatic deductions for all donors
# Note: query will be quite slow
SELECT c.ContactId, d.frequency, p.frequency
FROM contacts c
LEFT JOIN (SELECT ContactId, COUNT(*) AS frequency
           FROM acts WHERE ActType LIKE "DO"
           GROUP BY 1) AS d
ON c.ContactId = d.ContactId
LEFT JOIN (SELECT ContactId, COUNT(*) AS frequency
           FROM acts WHERE ActType LIKE "PA"
           GROUP BY 1) AS p
ON c.ContactId = p.ContactId
ORDER BY c.ContactId;
