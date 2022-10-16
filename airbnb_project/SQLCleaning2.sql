
--------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------- AIRBNB - SQL DATA CLEANING #2 ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------

-- DATASET WAS PRE-PROCESSED IN EXCEL BEFORE LOADING INTO SQL SERVER - THE instant_bookable column (BOOLEAN - TRUE/FALSE) CONTAINED --
-- BLANK VALUES PREVENTING IMPORT. THESE BLANK FIELDS WERE FILLED WITH FALSE TO GET THE DATASET UPLOADED -- 

USE airbnb;

SELECT * FROM airbnbdata;


-- CREATE COPY OF DATASET --

SELECT * INTO airbnbdatacopy
FROM 
	(SELECT * FROM airbnbdata) AS airbnbdatacopy;

/* MAKING COLUMN NAMES UNIFORM */

-- CHECKING THE CURRENT COLUMN NAMES -- 

SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'airbnbdatacopy';

-- RENAME COLUMNS IN airbnb TABLE --

EXEC sp_RENAME 'airbnbdatacopy.id','airbnb_id','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.NAME','name','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.host id','airbnb_host_id','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.host name','host_name','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.neighbourhood group','neighborhood_group','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.neighbourhood','neighborhood','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.country code','country_code','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.room type','room_type','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.Construction year','construction_year','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.service fee','service_fee','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.minimum nights','minimum_nights','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.number of reviews','number_of_reviews','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.last review','last_review','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.reviews per month','reviews_per_month','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.review rate number','review_rate_number','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.calculated host listings count','calculated_host_listings_cnt','COLUMN';
EXEC sp_RENAME 'airbnbdatacopy.availability 365','availability_365','COLUMN';

SELECT * FROM airbnbdatacopy

-- CHECKING THE NEW COLUMN NAMES -- 

SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'airbnbdatacopy';

/* FIXING SPELLING ERRORS */

-- CHECKING THE DIFFERENT VALUES SHOWING IN THE neighborhood_group COLUMN -- 

SELECT neighborhood_group, COUNT(neighborhood_group) AS 'Count'
FROM airbnbdatacopy
GROUP BY neighborhood_group
ORDER BY neighborhood_group;

-- CORRECTING THE VALUE 'brookln' TO 'Brooklyn' --

UPDATE airbnbdatacopy
SET neighborhood_group = CASE 
							WHEN neighborhood_group = 'brookln' THEN 'Brooklyn'
							ELSE neighborhood_group
							END;

-- CORRECTING THE VALUE 'manhatan' TO 'Manhattan' --

UPDATE airbnbdatacopy
SET neighborhood_group = CASE 
							WHEN neighborhood_group = 'manhatan' THEN 'Manhattan'
							ELSE neighborhood_group
							END;

-- CHECKING UPDATES -- 

SELECT neighborhood_group, COUNT(neighborhood_group) AS 'Count'
FROM airbnbdatacopy
GROUP BY neighborhood_group
ORDER BY neighborhood_group;


/* DUPLICATES */

-- CHECKING FOR DUPLICATES -- 

WITH duplicates AS
		(SELECT airbnb_id, ROW_NUMBER() OVER (PARTITION BY airbnb_id, airbnb_host_id ORDER BY airbnb_id) AS ROW_NUM
		FROM airbnbdatacopy)
SELECT * FROM duplicates WHERE ROW_NUM > 1;


-- DELETING DUPLICATES --

WITH duplicates AS
		(SELECT airbnb_id, ROW_NUMBER() OVER (PARTITION BY airbnb_id, airbnb_host_id ORDER BY airbnb_id) AS ROW_NUM
		FROM airbnbdatacopy)
DELETE FROM duplicates WHERE ROW_NUM > 1;


/* HANDLING NULLS */

 -- CHECKING THE NUMBER OF NULL VALUES EXIST IN THE country, country_code --
 -- AND neighborhood_group COLUMNS --

SELECT COUNT(*) AS 'nulls_country' FROM airbnbdatacopy WHERE country IS NULL;

SELECT COUNT(*) AS 'nulls_country_code'FROM airbnbdatacopy WHERE country_code IS NULL;

SELECT COUNT(*) AS 'nulls_neighborhood_group' FROM airbnbdatacopy WHERE neighborhood_group IS NULL; 


-- FIXING THE NULL VALUES IN THE country AND country_code COLUMNS --

UPDATE airbnbdatacopy
SET country = ISNULL(country, 'United States') FROM airbnbdatacopy;

UPDATE airbnbdatacopy
SET country_code = ISNULL(country_code, 'US') FROM airbnbdatacopy;


-- FIXING THE NULL VALUES IN THE neighborhood_group COLUMN --


-- CREATE A TEMP TABLE THAT GROUPS TOGETHER neighborhood_groups AND neighborhood WHERE VALUES ARE NOT NULL --
-- LATER TO JOIN THE TEMP TABLE WITH airbnbdata TABLE TO FILL NULL VALUES -- 

-- CREATE TEMP TABLE CALLED neighborhoods -- 

SELECT * INTO #neighborhoods
FROM
(SELECT neighborhood_group, neighborhood
FROM airbnbdatacopy
WHERE neighborhood_group IS NOT NULL AND neighborhood IS NOT NULL
GROUP BY neighborhood_group, neighborhood) AS #neighborhoods;

-- SETTING THE NULL VALUES IN THE neighborhood_group COLUMN -- 

UPDATE a
SET neighborhood_group =  ISNULL(a.neighborhood_group, n.neighborhood_group)
							FROM airbnbdatacopy a
							LEFT JOIN #neighborhoods n
							ON a.neighborhood = n.neighborhood;




/* DATA MANIPULATION */

-- CREATING COLUMN TO INDICATE WHETHER NON-SMOKING OR SMOKING ALLOWED IS MENTIONED IN house_rules COLUMN -- 


-- SELECTING LOCATIONS THAT MENTION NO SMOKING -- 

SELECT airbnb_id, house_rules FROM airbnbdatacopy WHERE house_rules LIKE '%no smoke%' OR house_rules LIKE '%no smoking%' ORDER BY airbnb_id

-- SELECTING LOCATIONS THAT MENTION SMOKING ALLOWED -- 

SELECT airbnb_id, house_rules FROM airbnbdatacopy WHERE house_rules LIKE 'smoking allowed%' ORDER BY airbnb_id;


-- ADDING smoking COLUMN --

ALTER TABLE airbnbdatacopy
ADD smoking NVARCHAR(10);

-- SETTING smoking COLUMN WITH CASE STATEMENT -- 

UPDATE airbnbdatacopy
SET smoking = CASE WHEN house_rules LIKE '%no smoke%' OR house_rules LIKE '%no smoking%' THEN 'No'
					WHEN house_rules LIKE 'smoking allowed%' THEN 'Yes'
					ELSE 'Unknown'
				END

-- CHECKING smoking COLUMN UPDATE -- 

SELECT smoking, COUNT(smoking) AS 'Smoking'
FROM airbnbdatacopy
GROUP BY smoking;

SELECT TOP(3) airbnb_id, house_rules, smoking
FROM airbnbdatacopy
WHERE smoking = 'Yes';

-- CREATING COLUMN TO INDICATE WHETHER PETS ALLOWED OR NOT IS MENTIONED IN house_rules COLUMN  -- 

-- SELECTING LOCATIONS THAT MENTION NO PETS ALLOWED -- 

SELECT airbnb_id, house_rules FROM airbnbdatacopy WHERE house_rules LIKE 'no pets%' ORDER BY airbnb_id

-- SELECTING LOCATIONS THAT MENTION PETS ALLOWED --

SELECT airbnb_id, house_rules FROM airbnbdatacopy WHERE house_rules LIKE 'pets allowed%' ORDER BY airbnb_id

-- ADDING pets COLUMN --

ALTER TABLE airbnbdatacopy
ADD pets NVARCHAR(10);

-- SETTING pets COLUMN -- 

UPDATE airbnbdatacopy
SET pets = CASE WHEN house_rules LIKE 'no pets%' THEN 'No'
				WHEN house_rules LIKE 'pets allowed%' THEN 'Yes'
				ELSE 'Unknown'
			END
			FROM airbnbdatacopy

-- CHECKING pets COLUMN UPDATE -- 

SELECT pets, COUNT(pets) AS 'Pets'
FROM airbnbdatacopy
GROUP BY pets;

SELECT TOP(3) airbnb_id, house_rules, pets
FROM airbnbdatacopy
WHERE pets = 'Yes';

-- CREATING COLUMN TO INDICATE WHETHER FREE WIFI WAS MENTIONED IN house_rules COLUMN -- 

-- SELECTING LOCATIONS THAT MENTION FREE WIFI -- 
SELECT house_rules FROM airbnbdatacopy WHERE house_rules LIKE 'free wifi%'

-- ADDING wifi COLUMN -- 

ALTER TABLE airbnbdatacopy
ADD wifi NVARCHAR(10);

-- SETTING wifi COLUMN -- 

UPDATE airbnbdatacopy
SET wifi = CASE WHEN house_rules LIKE 'free wifi%' THEN 'Yes'
				ELSE 'Unknown'
			END

-- CHECKING wifi COLUMN UPDATE -- 

SELECT wifi, COUNT(wifi) AS 'wifi'
FROM airbnbdatacopy
GROUP BY wifi

SELECT TOP(3) airbnb_id, house_rules, wifi
FROM airbnbdatacopy
WHERE wifi = 'Yes';


/* REMOVING UNNECESSARY COLUMNS & DELETING TEMP TABLE */

-- DELETING instant_bookable COLUMN -- 

ALTER TABLE airbnbdatacopy
DROP COLUMN instant_bookable

-- DELETING neighborhoods TEMP TABLE -- 

DROP TABLE #neighborhoods







