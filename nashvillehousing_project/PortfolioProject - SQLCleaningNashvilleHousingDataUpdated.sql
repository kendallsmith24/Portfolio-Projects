-- Project Dataset found at https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx
-- DATA CLEANING PROJECT IN SQL

SELECT *
FROM PortfolioProject..NashvilleHousingUpdated$

------------------------------------------------------------------------------------------------

-- STANDARDIZE DATE FORMAT

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousingUpdated$

UPDATE NashvilleHousingUpdated$
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousingUpdated$
ADD SaleDateConverted DATE;

UPDATE NashvilleHousingUpdated$
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM PortfolioProject..NashvilleHousing

-----------------------------------------------------------------------------------------------

-- POPULATE PROPERTY ADDRESS DATA WHERE PROPERTY ADDRESS IS NULL

SELECT *
FROM PortfolioProject..NashvilleHousingUpdated$
ORDER BY ParcelID

-- below query joins table with itself with ParcelID and UniqueID to find rows where PropertyAddress is null
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousingUpdated$ a
JOIN PortfolioProject..NashvilleHousingUpdated$ b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- below query sets rows where the a.PropertyAddress is null to the b.PropertyAddress  
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousingUpdated$ a
JOIN PortfolioProject..NashvilleHousingUpdated$ b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]

	----------------------------------------------------------------------------------------------

-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousingUpdated$
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

--CHARINDEX looking for (searching for specific value) (cont'd below)
--Character Index - in this case the comma (,) is the delimiter (separater of values in columns) between the address and city, state in the PropertyAddress Column
-- -1 eliminates the comma (,) from the output once query is run

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address
-- 2nd SUBSTRING focuses on locating the second portion of the address (in this case City)
-- +1 goes to the comma (,) itself, then specify where search should finish
FROM PortfolioProject..NashvilleHousingUpdated$

-- creating two new columns and values into table

ALTER TABLE NashvilleHousingUpdated$
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousingUpdated$
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousingUpdated$
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousingUpdated$
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousingUpdated$

-- using PARSENAME to separate Address, City, and State from OwnerAddress to create new columns instead of using SUBSTRING

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) 
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousingUpdated$

ALTER TABLE NashvilleHousingUpdated$
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousingUpdated$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousingUpdated$
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousingUpdated$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousingUpdated$
ADD PropertySplitState Nvarchar(255);

UPDATE NashvilleHousingUpdated$
SET PropertySplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM PortfolioProject..NashvilleHousingUpdated$

-- CHANGE Y AND N TO YES AND NO IN "Sold as Vacant" field

-- DISTINCT used to get count of distinct values within SoldAsVacant column
SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject..NashvilleHousingUpdated$
GROUP BY SoldAsVacant
ORDER BY 2

-- CASE statement used to change any occurrences of 'Y' or 'N' in SoldAsVacant column to 'Yes' or 'No', respectively
SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
		END
FROM PortfolioProject..NashvilleHousingUpdated$

UPDATE NashvilleHousingUpdated$
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
		END

		-----------------------------------------------------------------------------------------------------------



-- DELETE UNUSED COLUMNS (below query will remove OwnerAddress, TaxDistrict, PropertyAddress and SaleDate columns)

SELECT *
From PortfolioProject..NashvilleHousingUpdated$

ALTER TABLE PortfolioProject..NashvilleHousingUpdated$
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject..NashvilleHousingUpdated$
DROP COLUMN SaleDate




---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SELECT NULL VALUES IN PropertySplitState and replace with TN

SELECT *
From PortfolioProject..NashvilleHousingUpdated$

SELECT PropertySplitState
, ISNULL(PropertySplitState,' TN')
FROM PortfolioProject..NashvilleHousingUpdated$

UPDATE PortfolioProject..NashvilleHousingUpdated$
SET PropertySplitState = ISNULL(PropertySplitState,' TN')
FROM PortfolioProject..NashvilleHousingUpdated$

SELECT*
FROM PortfolioProject..NashvilleHousingUpdated$

-- SELECT NULL VALUES IN OwnerSplitAddress and replace with corresponding PropertySplitAddress

SELECT OwnerSplitAddress
, ISNULL(OwnerSplitAddress,PropertySplitAddress)
FROM PortfolioProject..NashvilleHousingUpdated$

UPDATE PortfolioProject..NashvilleHousingUpdated$
SET OwnerSplitAddress = ISNULL(OwnerSplitAddress,PropertySplitAddress)
FROM PortfolioProject..NashvilleHousingUpdated$

-- SELECT NULL VALUES IN OwnerSplitCity and replace with corresponding PropertySplitCity

SELECT OwnerSplitCity
, ISNULL(OwnerSplitCity, PropertySplitCity)
FROM PortfolioProject..NashvilleHousingUpdated$

UPDATE PortfolioProject..NashvilleHousingUpdated$
SET OwnerSplitCity = ISNULL(OwnerSplitCity, PropertySplitCity)
FROM PortfolioProject..NashvilleHousingUpdated$


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- QUERIES THAT CAN BE USED TO CREATE TABLEAU DASHBOARD -- 

SELECT*
FROM PortfolioProject..NashvilleHousingUpdated$

-- SELECTING ALL ROWS ORDERING BY UNIQUEID
SELECT *
FROM PortfolioProject..NashvilleHousingUpdated$
ORDER BY [UniqueID ] 

-- SELECTING THE NUMBER OF PROPERTIES BY PROPERTY TYPE IN DESCENDING ORDER
SELECT DISTINCT LandUse as 'Property Type', COUNT(LandUse) as 'Number of Properties'
FROM PortfolioProject..NashvilleHousingUpdated$
GROUP BY LandUse
ORDER BY 'Number of Properties' DESC

-- SELECTING THE TOTAL AVERAGE LAND VALUE OF EACH PROPERTY TYPE
SELECT DISTINCT LandUse as 'Property Type', AVG(LandValue) as 'Total Avg. Land Value by Property Type'
FROM PortfolioProject..NashvilleHousingUpdated$
WHERE LandValue is not null
GROUP BY LandUse
ORDER BY 'Total Avg. Land Value by Property Type' DESC

-- BELOW QUERIES USED TO CHECK IF TOTAL AVERAGE LAND VALUE QUERY ABOVE IS CORRECT
--SELECT LandUse, AVG(LandValue)
--FROM PortfolioProject..NashvilleHousingUpdated$
--WHERE LandUse = 'STRIP SHOPPING CENTER'
--GROUP BY LandUse

--SELECT LandUse, AVG(LandValue)
--FROM PortfolioProject..NashvilleHousingUpdated$
--WHERE LandUse = 'SINGLE FAMILY'
--GROUP BY LandUse

-- SELECTING TOTAL ACREAGE OF EACH PROPERTY TYPE

SELECT DISTINCT LandUse as 'Property Type', SUM(Acreage) as 'Total Acreage'
FROM PortfolioProject..NashvilleHousingUpdated$
WHERE LandUse is not null and Acreage is not null
GROUP BY LandUse 
ORDER BY 'Total Acreage' DESC

-- SELECTING TOTAL VALUE OF ALL PROPERTY TYPES

SELECT DISTINCT LandUse as 'Property Type', SUM(TotalValue) as 'Total Value'
FROM PortfolioProject..NashvilleHousingUpdated$
WHERE LandUse is not null and TotalValue is not null
GROUP BY LandUse
ORDER BY 'Total Value' DESC

SELECT *
FROM PortfolioProject..NashvilleHousingUpdated$
ORDER BY [UniqueID ]

-- SELECTING THE TOTAL NUMBER OF PROPERTIES BUILT BY CITY

SELECT DISTINCT OwnerSplitCity as 'City', COUNT([UniqueID ]) as 'Number of Properties Built'
FROM PortfolioProject..NashvilleHousingUpdated$
GROUP BY OwnerSplitCity
ORDER BY 'Number of Properties Built' DESC

-- SELECTING THE TOTAL AVERAGE LAND VALUE OF EACH CITY

SELECT DISTINCT OwnerSplitCity as 'City', AVG(LandValue) as 'Total Avg. Land Value by City'
FROM PortfolioProject..NashvilleHousingUpdated$
WHERE LandValue is not null
GROUP BY OwnerSplitCity
ORDER BY 'Total Avg. Land Value by City' DESC

-- SELECTING TOTAL ACREAGE BY CITY

SELECT DISTINCT OwnerSplitCity as 'City', SUM(Acreage) as 'Total Acreage'
FROM PortfolioProject..NashvilleHousingUpdated$
WHERE Acreage is not null
GROUP BY OwnerSplitCity
ORDER BY 'Total Acreage' DESC

-- SELECTING TOTAL VALUE OF PROPERTY BY CITY

SELECT DISTINCT OwnerSplitCity as 'City', SUM(TotalValue) as 'Total Property Value'
FROM PortfolioProject..NashvilleHousingUpdated$
WHERE TotalValue is not null
GROUP BY OwnerSplitCity
ORDER BY 'Total Property Value' DESC

-- SELECTING NUMBER OF PROPERTIES BUILT BY YEAR

SELECT DISTINCT YearBuilt, COUNT(UniqueID) as 'Number of Properties Built'
FROM PortfolioProject..NashvilleHousingUpdated$
WHERE YearBuilt is not null
GROUP BY YearBuilt
ORDER BY YearBuilt

-- BELOW QUERIES USED TO CHECK IF QUERY ABOVE IS CORRECT
--SELECT COUNT(*)
--FROM PortfolioProject..NashvilleHousingUpdated$
--WHERE YearBuilt = '1997'

--SELECT COUNT(*)
--FROM PortfolioProject..NashvilleHousingUpdated$
--WHERE YearBuilt = '1910'
