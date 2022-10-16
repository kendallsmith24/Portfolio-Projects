USE NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- NASHVILLE HOUSING - SQL DATA CLEANING #1 ---------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM housing;

/* CREATE COPY OF housing TABLE */

DROP TABLE housingcopy;

SELECT * INTO housingcopy
FROM 
	(SELECT * FROM housing) AS housingcopy;

SELECT * FROM housingcopy;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* CHECKING THE DATATYPES OF EACH OF THE COLUMNS */ 

SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'housingcopy';

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* HANDLING DUPLICATES */

-- CHECK FOR DUPLICATES -- 

WITH duplicates AS 
			(SELECT UniqueID, ROW_NUMBER() OVER (PARTITION BY UniqueID ORDER BY UniqueID) AS ROW_NUM
			FROM housingcopy)
SELECT * FROM duplicates WHERE ROW_NUM > 1;


-- DELETING DUPLICATES -- 

WITH duplicates AS 
			(SELECT UniqueID, ROW_NUMBER() OVER (PARTITION BY UniqueID ORDER BY UniqueID) AS ROW_NUM
			FROM housingcopy)
DELETE FROM duplicates WHERE ROW_NUM > 1;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* SPLITTING THE SaleDate COLUMN INTO SaleMonth, SaleDay, SaleYear COLUMNS TO ADD TO TABLE */ 

SELECT SaleDate FROM housingcopy;

-- CREATING SaleMonth COLUMN -- 

ALTER TABLE housingcopy
ADD SaleMonth INT;

UPDATE housingcopy
SET SaleMonth = MONTH(SaleDate) FROM housingcopy;

-- CREATING SaleDay COLUMN -- 

ALTER TABLE housingcopy
ADD SaleDay INT;

UPDATE housingcopy
SET SaleDay = DAY(SaleDate) FROM housingcopy;

-- CREATING SaleYear COLUMN --

ALTER TABLE housingcopy
ADD SaleYear INT; 

UPDATE housingcopy
SET SaleYear = YEAR(SaleDate) FROM housingcopy; 

-- CHECKING SaleDate, SaleMonth, SaleDay, AND SaleYear COLUNNS --

SELECT SaleDate, SaleMonth, SaleDay, SaleYear FROM housingcopy;

SELECT PropertyAddress, ISNULL(OwnerAddress, PropertyAddress)
FROM housingcopy

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* HANDLING NULLS */

-- HANDLING NULLS IN PropertyAddress AND OwnerAddress COLUMNS --

SELECT * FROM housingcopy

-- FILLING NULL VALUES IN PropertyAddress WITH VALUES IN OwnerAddress -- 

-- USING SELF JOIN ON ParcelID AND UniqueID TO FIND AND FILL ROWS WHERE PropertyAddress IS NULL --

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
							FROM housingcopy AS a
							JOIN housingcopy AS b
							ON a.ParcelID = b.ParcelID AND a.[UniqueID ]<> b.[UniqueID ];

-- CHECKING BOTH THE PropertyAddress AND OwnerAddress COLUMNS FOR COMPARISON --

SELECT PropertyAddress, OwnerAddress
FROM housingcopy; 

-- FILLING NULL VALUES IN OwnerAddress WITH VALUES IN PropertyAddress --

-- LOOKING AT THE FIRST 10 ROWS, IT APPEARS THAT THE VALUES IN THE PropertyAddress COLUMN ARE THE SAME AS THE VALUES --
-- IN THE OwnerAddress COLUMN, EXCEPT FOR THE STATE (TN) PRESENT IN THE OwnerAddress COLUMN (NOT SHOWN IN PropertyAddress) --
-- SINCE THIS IS THE CASE, THE VALUE FOR THE PropertyAddress WILL BE USED TO FILL ANY NULL VALUES IN THE OwnerAddress COLUMN --
-- THE STATE (TN) WILL BE ADDRESSED LATER WHEN SPLITTING THE ADDRESS INTO INDIVIDUAL COLUMNS -- 

UPDATE housingcopy
SET OwnerAddress = ISNULL(OwnerAddress, PropertyAddress) FROM housingcopy;

-- SELECTING OwnerAddress VALUES WHERE STATE(TN) IS NOT PRESENT --

SELECT OwnerAddress FROM housingcopy WHERE OwnerAddress NOT LIKE '%, TN%'  

-- SETTING THESE VALUES WITH THE STATE(TN) USING CONCAT -- 

UPDATE housingcopy
SET OwnerAddress = CONCAT(OwnerAddress, ', TN')
							FROM housingcopy
							WHERE OwnerAddress NOT LIKE '%, TN%'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* HANDLING ADDRESSES */

-- BREAKING THE PropertyAddress COLUMN INTO INDIVIDUAL ADDRESS, CITY, AND STATE COLUMNS --

SELECT PropertyAddress FROM housingcopy;

-- SELECTING THE ADDRESS NAME FROM THE PropertyAddress COLUMN -- 
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) FROM housingcopy;

-- ADDING PropertyAddressName COLUMN TO THE housingcopy TABLE -- 

ALTER TABLE housingcopy
ADD PropertyAddressName NVARCHAR(255);

-- SETTING PropertyAddressName -- 
UPDATE housingcopy
SET PropertyAddressName = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) FROM housingcopy;

-- SELECTING THE CITY FROM THE PropertyAddress COLUMN -- 
SELECT SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) FROM housingcopy;

-- ADDING PropertyAddressCity COLUMN TO THE housingcopy TABLE -- 

ALTER TABLE housingcopy
ADD PropertyAddressCity NVARCHAR(255);

-- SETTING PropertyAddressName -- 

UPDATE housingcopy
SET PropertyAddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) FROM housingcopy;

-- ADDING PropertyAddressState COLUMN TO THE housingcopy TABLE --

ALTER TABLE housingcopy
ADD PropertyAddressState VARCHAR(10);

-- SETTING PropertyAddressState -- 

UPDATE housingcopy
SET PropertyAddressState = 'TN'

-- CHECKING THE NEW PropertyAddress COLUMNS --

SELECT PropertyAddress, PropertyAddressName, PropertyAddressCity, PropertyAddressState
FROM housingcopy;

-- CREATING INDIVIDUAL AddressName, AddressCity, AND AddressState COLUMNS FOR THE OwnerAddress COLUMN -- 
-- INDIVIDUAL COLUMNS WILL BE SET USING THE PropertyAddress COLUMNS -- 

ALTER TABLE housingcopy
ADD OwnerAddressName NVARCHAR(255);

ALTER TABLE housingcopy
ADD OwnerAddressCity NVARCHAR(255);

ALTER TABLE housingcopy
ADD OwnerAddressState VARCHAR(10);

UPDATE housingcopy
SET OwnerAddressName = PropertyAddressName FROM housingcopy;

UPDATE housingcopy
SET OwnerAddressCity = PropertyAddressCity FROM housingcopy;

UPDATE housingcopy
SET OwnerAddressState = PropertyAddressState FROM housingcopy;

-- CHECKING THE NEW OwnerAddress COLUMNS -- 

SELECT OwnerAddress, OwnerAddressName, OwnerAddressCity, OwnerAddressState
FROM housingcopy;

-- DROPPING THE MULTIPART ADDRESS COLUMNS (PropertyAddress & OwnerAddress) -- 

ALTER TABLE housingcopy
DROP COLUMN PropertyAddress;

ALTER TABLE housingcopy
DROP COLUMN OwnerAddress;

SELECT * FROM housingcopy

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* HANDLING VALUES WITH THE SAME MEANING IN SoldAsVacant COLUMN */ 

-- CHECKING DISTINCT VALUES IN SoldAsVacant COLUMN -- 

SELECT SoldAsVacant, COUNT(SoldAsVacant) AS 'Counts' FROM housingcopy GROUP BY SoldAsVacant;

-- CHANGING ALL OCCURENCES OF 'Yes' AND 'No' TO 'Y' AND 'N' -- 

UPDATE housingcopy
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'Yes' THEN 'Y'
						WHEN SoldAsVacant = 'No' THEN 'N'
						ELSE SoldAsVacant
					END

-- CHECKING SoldAsVacant COLUMN -- 

SELECT SoldAsVacant, COUNT(SoldAsVacant) AS 'Counts' FROM housingcopy GROUP BY SoldAsVacant;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* SPLITTING OWNERNAME INTO INDIVIDUAL OWNER COLUMNS (owner1, owner2, owner3, owner4) */
-- LOOKING AT THE OwnerName COLUMN IT CAN SEEN THAT EACH OWNER IS SEPARATED BY THE '&' CHARACTER, SINCE THIS IS THE CASE THE '&' WILL BE USED AS THE --
-- PRIMARY DELIMITER TO EXTRACT EACH OWNER INTO ITS OWN INDIVIDUAL COLUMN -- 
-- TO MAKE THE PROCESS EASIER, I WILL GROUP TOGETHER THE OwnerName BASED ON THE NUMBER OF OWNERS IN EACH FIELD BASED ON THE NUMBER OF '&' THAT ARE PRESENT -- 
-- IF '&' SHOWS UP 3 TIMES IN OwnerName = 4 DIFFERENT OWNERS, 2 TIMES = 3 DIFFERENT OWNERS, 1 TIME = 2 DIFFERENT OWNERS, 0 = 1 OWNER -- 

/* SELECTING OwnerName AND COUNT THAT '&' OCCURS IN TEXT FIELD */
SELECT OwnerName, LEN(OwnerName) - LEN(REPLACE(OwnerName, '&','')) AS 'Count of &'
FROM housingcopy

-- SELECT OwnerName WHERE '&' OCCURS THREE TIMES -- 
SELECT OwnerName
FROM housingcopy
WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 3;

-- SELECT OwnerName WHERE '&' OCCURS TWICE -- 
SELECT OwnerName
FROM housingcopy
WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 2;

-- SELECT OwnerName WHERE '&' OCCURS ONCE -- 
SELECT OwnerName
FROM housingcopy
WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 1;

-- SELECT OwnerName WHERE '&' DOES NOT OCCUR -- 
SELECT OwnerName
FROM housingcopy
WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 0;




/* FINDING THE OWNERS WHERE '&' DOES NOT OCCUR ONCE -- INDICATES ONLY ONE OWNER THE FOR THE PROPERTY */

SELECT OwnerName, OwnerName AS 'owner1'
FROM housingcopy
WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 0 OR
OwnerName IN ('%ASSOCIATE%','%LLC%','%INVESTMENTS%','%L.P.%','%TRUST%','%INC%','%GOV''T%'); -- INCLUDING ANY REFERENCES TO COMPANY OWNERSHIP (INC, LLC, ETC.) --


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* FINDING THE FIRST AND SECOND OWNERS WHERE '&' OCCURS ONLY ONCE -- INDICATES TWO OWNERS FOR THE PROPERTY */ 

WITH owners AS
-- owners CTE SEPARATES THE LAST NAME FROM THE FIRST OWNER AND THE STRING TO THE RIGHT OF THE '&' AS SECOND NAME --
		(SELECT OwnerName, 
		REPLACE(LEFT(OwnerName, PATINDEX('%,%',OwnerName)),',','') AS 'last_name', -- EXTRACTS EVERYTHING LEFT OF THE ',' (LAST NAME OF FIRST OWNER) -- 
		SUBSTRING(OwnerName, 1, PATINDEX('%&%', OwnerName) - 1) AS 'first_owner', -- EXTRACTS EVERYTHING LEFT OF THE '&' (FIRST OWNER, LAST AND FIRST NAME) --
		LTRIM(REPLACE(RIGHT(OwnerName, PATINDEX('%&%', REVERSE(OwnerName))),'&','')) AS 'second_name' -- EXTRACTS EVERYTHING RIGHT OF THE '&' --
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 1 -- SELECTS ONLY RECORDS WHERE '&' OCCURS ONCE --
		AND OwnerName NOT LIKE '%ASSOCIATE%' AND OwnerName NOT LIKE '%LLC%' AND OwnerName NOT LIKE '%INVESTMENTS%'
		AND OwnerName NOT LIKE '%L.P.%' AND OwnerName NOT LIKE '%TRUST%' AND OwnerName NOT LIKE '%INC%' AND OwnerName NOT LIKE '%GOV''T%'),
	owners2 AS
-- owners2 CTE ADDS A CASE STATEMENT WHERE IF THE second_name DOES NOT CONTAIN ',' TO CONCAT TO THE last_name, ELSE LEAVE AS IS --
-- LOGIC IS THAT IF THE second_name CONTAINS A ',' THEN IT CONTAINS LAST NAME, FIRST NAME, OTHERWISE THE second_name HAS THE SAME LAST NAME AS THE FIRST OWNER -- 
		(SELECT OwnerName, first_owner AS 'owner1', 
		CASE WHEN second_name NOT LIKE '%,%' THEN CONCAT(last_name,', ',second_name)
				ELSE second_name
		END AS 'owner2' FROM owners)
SELECT * FROM owners2;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* FINDING THE FIRST, SECOND, AND THIRD OWNERS WHERE '&' OCCURS TWICE -- INDICATES THREE OWNERS FOR THE PROPERTY */ --

WITH owners3 AS
-- owners3 CTE SEPARATES THE LAST NAME FROM THE FIRST OWNER, THE FIRST OWNER NAME, THE SECOND OWNERS FIRST NAME AND THE THIRD OWNERS NAME -- 
		(SELECT OwnerName,
		REPLACE(LEFT(OwnerName, PATINDEX('%,%',OwnerName)),',','') AS 'last_name', -- PULLS STRING LEFT OF THE FIRST ',' IN THE OwnerName -- 
		SUBSTRING(OwnerName, 1, PATINDEX('%&%', OwnerName) - 1) AS 'first_owner', -- PULLS THE STRING LEFT OF THE POSITION OF THE 1st '&' IN THE OwnerName AS first_owner --
		LTRIM(SUBSTRING(OwnerName, CHARINDEX('&',OwnerName)+1, CHARINDEX('&',OwnerName, CHARINDEX('&',OwnerName) +1)-CHARINDEX('&',OwnerName)-1)) AS 'second_owner_fname',
		-- PULLS THE STRING BETWEEN THE 1st AND 2nd INSTANCE OF '&' IN THE OwnerName AS SECOND OWNERS FIRST NAME -- 
		LTRIM(REPLACE(RIGHT(OwnerName, PATINDEX('%&%', REVERSE(OwnerName))),'&','')) AS 'third_name' -- PULLS STRING RIGHT OF THE 2nd '&' IN THE OwnerName AS third_name
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 2 -- SELECTS ONLY RECORDS WHERE '&' OCCURS TWICE -- 
		AND OwnerName NOT LIKE '%ASSOCIATE%' AND OwnerName NOT LIKE '%LLC%' AND OwnerName NOT LIKE '%INVESTMENTS%'
		AND OwnerName NOT LIKE '%L.P.%' AND OwnerName NOT LIKE '%TRUST%' AND OwnerName NOT LIKE '%INC%' AND OwnerName NOT LIKE '%GOV''T%'),
	owners4 AS
		(SELECT OwnerName, first_owner AS 'owner1', 
			CASE WHEN second_owner_fname NOT LIKE '%,%' THEN CONCAT(last_name,', ',second_owner_fname)
			-- TAKES INSTANCES WHERE second_owner_fname DO NOT CONTAIN A ',' AND CONCATS THEM TO THE last_name, ELSE LEAVE AS IS --
				ELSE second_owner_fname
			END AS 'owner2',
			CASE WHEN third_name NOT LIKE '%,%' AND second_owner_fname NOT LIKE '%,%' THEN CONCAT(last_name,', ',third_name)
			-- TAKES INSTANCES WHERE third_name AND second_owner_fname DO NOT CONTAIN A ',' AND CONCATS TO last_name --
				WHEN third_name NOT LIKE '%,%' AND second_owner_fname LIKE '%,%' THEN CONCAT(REPLACE(LEFT(second_owner_fname, PATINDEX('%,%',second_owner_fname)),',',''),', ',third_name)
				-- TAKES INSTANCES WHERE third_name DOES NOT CONTAIN A ',' BUT second_owner_fname DOES CONTAIN A ',' AND EXTRACTS THE LAST NAME FROM second_owner_fname --
				-- AND CONCATS TO third_name -- 
				ELSE third_name
			END AS 'owner3'
			FROM owners3)
SELECT * FROM owners4;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* FINDING THE FIRST, SECOND, THIRD, FOURTH OWNERS WHERE '&' OCCURS 3 TIMES -- INDICATES FOUR OWNERS FOR THE PROPERTY */

WITH owners5 AS
-- owners5 CTE RETRIEVES THE OWNERNAME, last_name FROM 1st OWNER, first_owner, 2nd OWNERS FIRST NAME, AND FOURTH OWNERS NAME --
		(SELECT OwnerName,
		REPLACE(LEFT(OwnerName, PATINDEX('%,%',OwnerName)),',','') AS 'last_name',
		REPLACE(LEFT(OwnerName, PATINDEX('%&%',OwnerName)),'&','') AS 'first_owner',
		LTRIM(SUBSTRING(OwnerName, CHARINDEX('&',OwnerName)+1, CHARINDEX('&',OwnerName, CHARINDEX('&',OwnerName) +1)-CHARINDEX('&',OwnerName)-1)) AS 'second_owner_fname',
		LTRIM(REPLACE(RIGHT(OwnerName, PATINDEX('%&%', REVERSE(OwnerName))),'&','')) AS 'fourth_owner'
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 3 -- SELECTS ONLY RECORDS WHERE '&' OCCURS THREE TIMES --
		AND OwnerName NOT LIKE '%ASSOCIATE%' AND OwnerName NOT LIKE '%LLC%' AND OwnerName NOT LIKE '%INVESTMENTS%'
		AND OwnerName NOT LIKE '%L.P.%' AND OwnerName NOT LIKE '%TRUST%' AND OwnerName NOT LIKE '%INC%' AND OwnerName NOT LIKE '%GOV''T%'),  
-- third_name_position CTE RETRIEVES THE NUMERICAL POSITION OF THE 2ND INSTANCE OF '&' IN OwnerName THAT WILL BE NEEDED TO EXTRACT THE THIRD OWNER NAME CALLING IT position -- 
	third_name_position AS
		(SELECT OwnerName, CHARINDEX('&',OwnerName, (CHARINDEX('&',OwnerName,1))+1) AS 'position'
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 3),
-- third_name_position2 CTE USES THE position FROM THE third_name_position CTE TO RETURN THE SUBSTRING OF EVERYTHING RIGHT OF THE 2ND INSTANCE OF '&' IN OwnerName -- 
	third_name_position2 AS
		(SELECT OwnerName, SUBSTRING(OwnerName, position+1,LEN(OwnerName)-CHARINDEX('&',OwnerName)) AS 'third_name'
		FROM third_name_position
		WHERE OwnerName NOT LIKE '%L.P.%'),
-- third_name_position3 CTE EXTRACTS STRING LEFT OF THE ',' INTO COLUMN THAT WILL CONTAIN THE 3rd OWNERS LAST NAME (third_owner_lname)-- 
	third_name_position3 AS
		(SELECT OwnerName, LTRIM(REPLACE(LEFT(third_name, PATINDEX('%,%',third_name)),',','')) AS 'third_owner_lname', third_name
		FROM third_name_position2),
-- owners6 CTE TAKES THE OwnerName, last_name, first_owner, second_owner_fname AND fourth_owner FROM owners5 CTE. IT ALSO CHECKS THE second_owner_fname FOR ',' AND EXTRACTS EVERYTHING LEFT --
-- OF THE ',' AS THE 2nd OWNERS LAST NAME WHILE JOINING WITH THE third_name_position3 CTE ON OwnerName TO GET THE third_owner_lname AND CHECKING THE third_name FOR '&' AND EXTRACTING --
-- EVERYTHING LEFT OF THE '&' AS THE 3rd OWNER (third_owner)-- 
	owners6 AS
		(SELECT o.OwnerName, o.last_name, o.first_owner, REPLACE(LEFT(o.second_owner_fname, PATINDEX('%,%',o.second_owner_fname)),',','') AS 'second_owner_lname',
		o.second_owner_fname, n.third_owner_lname, REPLACE(LEFT(n.third_name, PATINDEX('%&%',n.third_name)),'&','') AS 'third_owner', o.fourth_owner
		FROM owners5 AS o
		JOIN third_name_position3 AS n
		ON o.OwnerName = n.OwnerName),
-- owners7 CTE BRINGS EVERYTHING TOGETHER, OwnerName, first_owner, second_owner, third_owner, fourth_owner -- 
	owners7 AS
		(SELECT OwnerName, first_owner AS 'owner1', 
			CASE WHEN second_owner_fname NOT LIKE '%,%' THEN CONCAT(last_name,', ',second_owner_fname)
				ELSE second_owner_fname
			END AS 'owner2', -- WHERE second_owner DOES NOT CONTAIN ',' CONCAT TO last_name, ELSE LEAVE AS IS (PRESENCE OF ',' INDICATES THAT second_owner_fname CONTAINS FIRST AND LAST NAME) --
			CASE WHEN third_owner NOT LIKE '%,%' AND third_owner_lname NOT LIKE '' AND third_owner_lname NOT LIKE '%&%' THEN CONCAT(third_owner_lname,', ',third_owner)
			-- IF ',' IS NOT IN third_owner, INDICATES NEED OF LAST NAME, IF third_owner_lname DOES NOT CONTAIN BLANKS OR '&' THEN CONCAT third_owner_lname TO third_owner -- 
				WHEN third_owner NOT LIKE '%,%' AND second_owner_lname NOT LIKE '' THEN CONCAT(second_owner_lname,', ',third_owner)
			-- IF ',' IS NOT IN third_owner, INDICATES NEED OF LAST NAME, IF second_owner_lname IS NOT BLANK THEN CONCAT second_owner_lname TO third_owner --
				WHEN third_owner NOT LIKE '%,%' THEN CONCAT(last_name,', ',third_owner)
			-- IF ',' IS NOT IN third_owner, INDICATES NEED OF LAST NAME, CONCAT last_name TO third_owner IF PREVIOUS CASE STATEMENTS ARE NOT SATISFIED -- 
				ELSE third_owner
			END AS 'owner3',
			CASE WHEN fourth_owner NOT LIKE '%,%' AND third_owner_lname NOT LIKE '' AND third_owner_lname NOT LIKE '%.%' AND third_owner_lname NOT LIKE '%&%' THEN CONCAT(third_owner_lname,', ',fourth_owner)
			-- IF ',' IS NOT IN fourth_owner, INDICATES NEED OF LAST NAME, IF third_owner_lname DOES NOT CONTAIN BLANKS, '.', AND '&' THEN CONCAT third_owner_lname TO fourth_owner -- 
				WHEN fourth_owner NOT LIKE '%,%' AND second_owner_lname NOT LIKE '' THEN CONCAT(second_owner_lname,', ',fourth_owner)
			-- IF ',' IS NOT IN fourth_owner, INDICATES NEED OF LAST NAME, IF second_owner_lname IS NOT BLANK THEN CONCAT second_owner_lname TO fourth_owner --
				WHEN fourth_owner NOT LIKE '%,%' THEN CONCAT(last_name,', ',fourth_owner)
			-- IF ',' IS NOT IN fourth_owner, INDICATES NEED OF LAST NAME, CONCAT last_name TO fourth_owner IF PREVIOUS CASE STATEMENTS ARE NOT SATISFIED -- 
				ELSE fourth_owner
			END AS 'owner4'
		FROM owners6)
SELECT * FROM owners7;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* ADDING OWNERS COLUMNS TO HOUSING TABLE */

-- ADDING owner1, owner2, owner3 AND owner4 COLUMNS -- 

ALTER TABLE housingcopy
ADD owner1 NVARCHAR(255);

ALTER TABLE housingcopy
ADD owner2 NVARCHAR(255);

ALTER TABLE housingcopy
ADD owner3 NVARCHAR(255);

ALTER TABLE housingcopy
ADD owner4 NVARCHAR(255);


/* CREATING OWNERS TEMP TABLES */

-- CREATING one_owner TEMP TABLE -- 

SELECT OwnerName, OwnerName AS 'owner1' INTO #one_owner
FROM housingcopy
WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 0 OR
OwnerName IN ('%ASSOCIATE%','%LLC%','%INVESTMENTS%','%L.P.%','%TRUST%','%INC%','%GOV''T%'); 



-- CREATING two_owners TEMP TABLE -- 

WITH owners AS
-- owners CTE SEPARATES THE LAST NAME FROM THE FIRST OWNER AND THE STRING TO THE RIGHT OF THE '&' AS SECOND NAME --
		(SELECT OwnerName, 
		REPLACE(LEFT(OwnerName, PATINDEX('%,%',OwnerName)),',','') AS 'last_name', -- EXTRACTS EVERYTHING LEFT OF THE ',' (LAST NAME OF FIRST OWNER) -- 
		SUBSTRING(OwnerName, 1, PATINDEX('%&%', OwnerName) - 1) AS 'first_owner', -- EXTRACTS EVERYTHING LEFT OF THE '&' (FIRST OWNER, LAST AND FIRST NAME) --
		LTRIM(REPLACE(RIGHT(OwnerName, PATINDEX('%&%', REVERSE(OwnerName))),'&','')) AS 'second_name' -- EXTRACTS EVERYTHING RIGHT OF THE '&' --
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 1 -- SELECTS ONLY RECORDS WHERE '&' OCCURS ONCE --
		AND OwnerName NOT LIKE '%ASSOCIATE%' AND OwnerName NOT LIKE '%LLC%' AND OwnerName NOT LIKE '%INVESTMENTS%'
		AND OwnerName NOT LIKE '%L.P.%' AND OwnerName NOT LIKE '%TRUST%' AND OwnerName NOT LIKE '%INC%' AND OwnerName NOT LIKE '%GOV''T%'),
	owners2 AS
-- owners2 CTE ADDS A CASE STATEMENT WHERE IF THE second_name DOES NOT CONTAIN ',' TO CONCAT TO THE last_name, ELSE LEAVE AS IS --
-- LOGIC IS THAT IF THE second_name CONTAINS A ',' THEN IT CONTAINS LAST NAME, FIRST NAME, OTHERWISE THE second_name HAS THE SAME LAST NAME AS THE FIRST OWNER -- 
		(SELECT OwnerName, first_owner AS 'owner1', 
		CASE WHEN second_name NOT LIKE '%,%' THEN CONCAT(last_name,', ',second_name)
				ELSE second_name
		END AS 'owner2' FROM owners)
SELECT * INTO #two_owners FROM owners2;

SELECT * FROM #two_owners

-- CREATING three_owners TEMP TABLE -- 

WITH owners3 AS
-- owners3 CTE SEPARATES THE LAST NAME FROM THE FIRST OWNER, THE FIRST OWNER NAME, THE SECOND OWNERS FIRST NAME AND THE THIRD OWNERS NAME -- 
		(SELECT OwnerName,
		REPLACE(LEFT(OwnerName, PATINDEX('%,%',OwnerName)),',','') AS 'last_name', -- PULLS STRING LEFT OF THE FIRST ',' IN THE OwnerName -- 
		SUBSTRING(OwnerName, 1, PATINDEX('%&%', OwnerName) - 1) AS 'first_owner', -- PULLS THE STRING LEFT OF THE POSITION OF THE 1st '&' IN THE OwnerName AS first_owner --
		LTRIM(SUBSTRING(OwnerName, CHARINDEX('&',OwnerName)+1, CHARINDEX('&',OwnerName, CHARINDEX('&',OwnerName) +1)-CHARINDEX('&',OwnerName)-1)) AS 'second_owner_fname',
		-- PULLS THE STRING BETWEEN THE 1st AND 2nd INSTANCE OF '&' IN THE OwnerName AS SECOND OWNERS FIRST NAME -- 
		LTRIM(REPLACE(RIGHT(OwnerName, PATINDEX('%&%', REVERSE(OwnerName))),'&','')) AS 'third_name' -- PULLS STRING RIGHT OF THE 2nd '&' IN THE OwnerName AS third_name
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 2 -- SELECTS ONLY RECORDS WHERE '&' OCCURS TWICE -- 
		AND OwnerName NOT LIKE '%ASSOCIATE%' AND OwnerName NOT LIKE '%LLC%' AND OwnerName NOT LIKE '%INVESTMENTS%'
		AND OwnerName NOT LIKE '%L.P.%' AND OwnerName NOT LIKE '%TRUST%' AND OwnerName NOT LIKE '%INC%' AND OwnerName NOT LIKE '%GOV''T%'),
	owners4 AS
		(SELECT OwnerName, first_owner AS 'owner1', 
			CASE WHEN second_owner_fname NOT LIKE '%,%' THEN CONCAT(last_name,', ',second_owner_fname)
			-- TAKES INSTANCES WHERE second_owner_fname DO NOT CONTAIN A ',' AND CONCATS THEM TO THE last_name, ELSE LEAVE AS IS --
				ELSE second_owner_fname
			END AS 'owner2',
			CASE WHEN third_name NOT LIKE '%,%' AND second_owner_fname NOT LIKE '%,%' THEN CONCAT(last_name,', ',third_name)
			-- TAKES INSTANCES WHERE third_name AND second_owner_fname DO NOT CONTAIN A ',' AND CONCATS TO last_name --
				WHEN third_name NOT LIKE '%,%' AND second_owner_fname LIKE '%,%' THEN CONCAT(REPLACE(LEFT(second_owner_fname, PATINDEX('%,%',second_owner_fname)),',',''),', ',third_name)
				-- TAKES INSTANCES WHERE third_name DOES NOT CONTAIN A ',' BUT second_owner_fname DOES CONTAIN A ',' AND EXTRACTS THE LAST NAME FROM second_owner_fname --
				-- AND CONCATS TO third_name -- 
				ELSE third_name
			END AS 'owner3'
			FROM owners3)
SELECT * INTO #three_owners FROM owners4;

-- CREATING four_owners TEMP TABLE --

WITH owners5 AS
-- owners5 CTE RETRIEVES THE OWNERNAME, last_name FROM 1st OWNER, first_owner, 2nd OWNERS FIRST NAME, AND FOURTH OWNERS NAME --
		(SELECT OwnerName,
		REPLACE(LEFT(OwnerName, PATINDEX('%,%',OwnerName)),',','') AS 'last_name',
		REPLACE(LEFT(OwnerName, PATINDEX('%&%',OwnerName)),'&','') AS 'first_owner',
		LTRIM(SUBSTRING(OwnerName, CHARINDEX('&',OwnerName)+1, CHARINDEX('&',OwnerName, CHARINDEX('&',OwnerName) +1)-CHARINDEX('&',OwnerName)-1)) AS 'second_owner_fname',
		LTRIM(REPLACE(RIGHT(OwnerName, PATINDEX('%&%', REVERSE(OwnerName))),'&','')) AS 'fourth_owner'
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 3 -- SELECTS ONLY RECORDS WHERE '&' OCCURS THREE TIMES --
		AND OwnerName NOT LIKE '%ASSOCIATE%' AND OwnerName NOT LIKE '%LLC%' AND OwnerName NOT LIKE '%INVESTMENTS%'
		AND OwnerName NOT LIKE '%L.P.%' AND OwnerName NOT LIKE '%TRUST%' AND OwnerName NOT LIKE '%INC%' AND OwnerName NOT LIKE '%GOV''T%'),  
-- third_name_position CTE RETRIEVES THE NUMERICAL POSITION OF THE 2ND INSTANCE OF '&' IN OwnerName THAT WILL BE NEEDED TO EXTRACT THE THIRD OWNER NAME CALLING IT position -- 
	third_name_position AS
		(SELECT OwnerName, CHARINDEX('&',OwnerName, (CHARINDEX('&',OwnerName,1))+1) AS 'position'
		FROM housingcopy
		WHERE LEN(OwnerName) - LEN(REPLACE(OwnerName,'&','')) = 3),
-- third_name_position2 CTE USES THE position FROM THE third_name_position CTE TO RETURN THE SUBSTRING OF EVERYTHING RIGHT OF THE 2ND INSTANCE OF '&' IN OwnerName -- 
	third_name_position2 AS
		(SELECT OwnerName, SUBSTRING(OwnerName, position+1,LEN(OwnerName)-CHARINDEX('&',OwnerName)) AS 'third_name'
		FROM third_name_position
		WHERE OwnerName NOT LIKE '%L.P.%'),
-- third_name_position3 CTE EXTRACTS STRING LEFT OF THE ',' INTO COLUMN THAT WILL CONTAIN THE 3rd OWNERS LAST NAME (third_owner_lname)-- 
	third_name_position3 AS
		(SELECT OwnerName, LTRIM(REPLACE(LEFT(third_name, PATINDEX('%,%',third_name)),',','')) AS 'third_owner_lname', third_name
		FROM third_name_position2),
-- owners6 CTE TAKES THE OwnerName, last_name, first_owner, second_owner_fname AND fourth_owner FROM owners5 CTE. IT ALSO CHECKS THE second_owner_fname FOR ',' AND EXTRACTS EVERYTHING LEFT --
-- OF THE ',' AS THE 2nd OWNERS LAST NAME WHILE JOINING WITH THE third_name_position3 CTE ON OwnerName TO GET THE third_owner_lname AND CHECKING THE third_name FOR '&' AND EXTRACTING --
-- EVERYTHING LEFT OF THE '&' AS THE 3rd OWNER (third_owner)-- 
	owners6 AS
		(SELECT o.OwnerName, o.last_name, o.first_owner, REPLACE(LEFT(o.second_owner_fname, PATINDEX('%,%',o.second_owner_fname)),',','') AS 'second_owner_lname',
		o.second_owner_fname, n.third_owner_lname, REPLACE(LEFT(n.third_name, PATINDEX('%&%',n.third_name)),'&','') AS 'third_owner', o.fourth_owner
		FROM owners5 AS o
		JOIN third_name_position3 AS n
		ON o.OwnerName = n.OwnerName),
-- owners7 CTE BRINGS EVERYTHING TOGETHER, OwnerName, first_owner, second_owner, third_owner, fourth_owner -- 
	owners7 AS
		(SELECT OwnerName, first_owner AS 'owner1', 
			CASE WHEN second_owner_fname NOT LIKE '%,%' THEN CONCAT(last_name,', ',second_owner_fname)
				ELSE second_owner_fname
			END AS 'owner2', -- WHERE second_owner DOES NOT CONTAIN ',' CONCAT TO last_name, ELSE LEAVE AS IS (PRESENCE OF ',' INDICATES THAT second_owner_fname CONTAINS FIRST AND LAST NAME) --
			CASE WHEN third_owner NOT LIKE '%,%' AND third_owner_lname NOT LIKE '' AND third_owner_lname NOT LIKE '%&%' THEN CONCAT(third_owner_lname,', ',third_owner)
			-- IF ',' IS NOT IN third_owner, INDICATES NEED OF LAST NAME, IF third_owner_lname DOES NOT CONTAIN BLANKS OR '&' THEN CONCAT third_owner_lname TO third_owner -- 
				WHEN third_owner NOT LIKE '%,%' AND second_owner_lname NOT LIKE '' THEN CONCAT(second_owner_lname,', ',third_owner)
			-- IF ',' IS NOT IN third_owner, INDICATES NEED OF LAST NAME, IF second_owner_lname IS NOT BLANK THEN CONCAT second_owner_lname TO third_owner --
				WHEN third_owner NOT LIKE '%,%' THEN CONCAT(last_name,', ',third_owner)
			-- IF ',' IS NOT IN third_owner, INDICATES NEED OF LAST NAME, CONCAT last_name TO third_owner IF PREVIOUS CASE STATEMENTS ARE NOT SATISFIED -- 
				ELSE third_owner
			END AS 'owner3',
			CASE WHEN fourth_owner NOT LIKE '%,%' AND third_owner_lname NOT LIKE '' AND third_owner_lname NOT LIKE '%.%' AND third_owner_lname NOT LIKE '%&%' THEN CONCAT(third_owner_lname,', ',fourth_owner)
			-- IF ',' IS NOT IN fourth_owner, INDICATES NEED OF LAST NAME, IF third_owner_lname DOES NOT CONTAIN BLANKS, '.', AND '&' THEN CONCAT third_owner_lname TO fourth_owner -- 
				WHEN fourth_owner NOT LIKE '%,%' AND second_owner_lname NOT LIKE '' THEN CONCAT(second_owner_lname,', ',fourth_owner)
			-- IF ',' IS NOT IN fourth_owner, INDICATES NEED OF LAST NAME, IF second_owner_lname IS NOT BLANK THEN CONCAT second_owner_lname TO fourth_owner --
				WHEN fourth_owner NOT LIKE '%,%' THEN CONCAT(last_name,', ',fourth_owner)
			-- IF ',' IS NOT IN fourth_owner, INDICATES NEED OF LAST NAME, CONCAT last_name TO fourth_owner IF PREVIOUS CASE STATEMENTS ARE NOT SATISFIED -- 
				ELSE fourth_owner
			END AS 'owner4'
		FROM owners6)
SELECT * INTO #four_owners FROM owners7;



-- JOINING THE TEMP TABLES TOGETHER WITH UNION -- 

SELECT * FROM #one_owner;
SELECT * FROM #two_owners;
SELECT * FROM #three_owners;
SELECT * FROM #four_owners;

SELECT * INTO #owners
FROM 
(SELECT OwnerName, owner1, NULL AS owner2, NULL AS owner3, NULL AS owner4 FROM #one_owner
UNION
SELECT OwnerName, owner1, owner2, NULL AS owner3, NULL AS owner4 FROM #two_owners
UNION
SELECT OwnerName, owner1, owner2, owner3, NULL AS owner4 FROM #three_owners
UNION 
SELECT * FROM #four_owners) AS #owners;


SELECT * FROM #owners


SELECT OwnerName, owner1, owner2, owner3, owner4 FROM housingcopy;


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- UPDATE FOR ONE OWNER --
UPDATE housingcopy
SET owner1 = h1.owner1 FROM #owners AS h1
					JOIN housingcopy AS o
					ON h1.OwnerName = o.OwnerName;

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- UPDATE FOR TWO OWNERS -- 
UPDATE housingcopy
SET owner2 = h2.owner2 FROM #owners AS h2
					JOIN housingcopy AS o
					ON h2.OwnerName = o.OwnerName;

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- UPDATE FOR THREE OWNERS -- 
UPDATE housingcopy
SET owner3 = h3.owner3 FROM #owners AS h3
					JOIN housingcopy AS o
					ON h3.OwnerName = o.OwnerName;


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- UPDATE FOR FOUR OWNERS -- 

UPDATE housingcopy
SET owner4 = h4.owner4 FROM #owners AS h4
					JOIN housingcopy AS o
					ON h4.OwnerName = o.OwnerName;

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

SELECT * FROM housingcopy



---------------------------------------------------------------------------------------------------------------
----------------------------------------- FINAL CLEAN-UP ------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

-- DELETING TEMP TABLES -- 

DROP TABLE #one_owner
DROP TABLE #two_owners
DROP TABLE #three_owners
DROP TABLE #four_owners
DROP TABLE #owners




--------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------- NASHVILLE HOUSING - ANALYSIS ------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------

-- ONCE CLEANED, THE BELOW QUERIES CAN BE USED PULL INFORMATION FROM THE DATASET -- 

-- FINDING THE TOTAL NUMBER OF EACH PROPERTY TYPE --

SELECT LandUse AS 'PropertyType', COUNT(LandUse) AS 'Number of Properties'
FROM housingcopy
GROUP BY LandUse
ORDER BY 'Number of Properties' DESC;

-- FINDING THE NUMBER OF PROPERTIES BUILT BY YEAR -- 

SELECT YearBuilt AS 'Year', COUNT(UniqueID) AS 'Number of Properties Built'
FROM housingcopy
WHERE YearBuilt IS NOT NULL
GROUP BY YearBuilt
ORDER BY YearBuilt;

-- FINDING THE NUMBER OF PROPERTIES TYPES BUILT EACH YEAR -- 

SELECT YearBuilt AS 'Year', LandUse AS 'PropertyType', COUNT(LandUse) AS 'Number of Properties Built'
FROM housingcopy
WHERE YearBuilt IS NOT NULL
GROUP BY YearBuilt, LandUse
ORDER BY 'Year', 'PropertyType';

-- FINDING THE AVERAGE LAND VALUE OF EACH PROPERTY TYPE -- 

SELECT LandUse AS 'PropertyType', ROUND(AVG(LandValue), 0) AS 'Avg. Land Value'
FROM housingcopy
GROUP BY LandUse
ORDER BY 'Avg. Land Value' DESC;

-- FINDING THE TOTAL ACREAGE OF EACH PROPERTY TYPE -- 

SELECT LandUse AS 'PropertyType', ROUND(SUM(Acreage), 0) AS 'Total'
FROM housingcopy
WHERE Acreage IS NOT NULL 
GROUP BY LandUse
ORDER BY 'Total' DESC;

-- FINDING TOTAL VALUE OF EACH PROPERTY TYPE --

SELECT LandUse AS 'PropertyType', SUM(TotalValue) AS 'TotalValue'
FROM housingcopy
WHERE TotalValue IS NOT NULL
GROUP BY LandUse
ORDER BY 'TotalValue' DESC;

-- FINDING THE TOTAL NUMBER OF PROPERTIES BUILT IN EACH CITY -- 

SELECT OwnerAddressCity AS 'City', COUNT(UniqueID) AS 'NumberofProperties'
FROM housingcopy
GROUP BY OwnerAddressCity
ORDER BY 'NumberofProperties' DESC; 

-- FINDING THE AVERAGE LAND VALUES OF EACH CITY -- 

SELECT OwnerAddressCity AS 'City', ROUND(AVG(LandValue), 0) AS 'Avg. LandValue'
FROM housingcopy
WHERE LandValue IS NOT NULL 
GROUP BY OwnerAddressCity
ORDER BY 'Avg. LandValue' DESC; 

-- FINDING TOTAL ACREAGE BY CITY -- 

SELECT OwnerAddressCity AS 'City', ROUND(SUM(Acreage), 0) AS 'Total Acreage'
FROM housingcopy
WHERE Acreage IS NOT NULL 
GROUP BY OwnerAddressCity
ORDER BY 'Total Acreage' DESC; 

-- FINDING TOTAL PROPERTY VALUE BY CITY --

SELECT OwnerAddressCity AS 'City', SUM(TotalValue) AS 'Total Property Value'
FROM housingcopy
WHERE TotalValue IS NOT NULL
GROUP BY OwnerAddressCity
ORDER BY 'Total Property Value' DESC; 




