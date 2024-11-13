-- Step 1: Populate Property Address Data
SELECT * 
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning`
ORDER BY ParcelID;

-- Step 2: Find Mismatched SalePrice for Same ParcelID where PropertyAddress is NULL
SELECT a.ParcelID, a.PropertyAddress, a.SalePrice, 
       b.ParcelID, b.PropertyAddress, b.SalePrice
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning` a
JOIN `boxing-quest-1234-2005.sample_dataset.data_cleaning` b
ON a.ParcelID = b.ParcelID
AND a.SalePrice <> b.SalePrice
WHERE a.PropertyAddress IS NULL;

-- Step 3: Merge to Update PropertyAddress where NULL
MERGE INTO `boxing-quest-1234-2005.sample_dataset.data_cleaning` a
USING `boxing-quest-1234-2005.sample_dataset.data_cleaning` b
ON a.ParcelID = b.ParcelID
AND a.SalePrice <> b.SalePrice
AND a.PropertyAddress IS NULL
WHEN MATCHED THEN
  UPDATE SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress);

-- Step 4: Break Out Address into Individual Columns (StreetAddress, City)
SELECT PropertyAddress
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning`
WHERE STRPOS(LOWER(TRIM(PropertyAddress)), LOWER('Main')) > 0;

SELECT
  PropertyAddress, 
  TRIM(REGEXP_EXTRACT(PropertyAddress, r'^(.*),')) AS StreetAddress, 
  TRIM(REGEXP_EXTRACT(PropertyAddress, r'[^,]+$')) AS SplitCity
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning`;

-- Step 5: Add and Update Split Address Columns
ALTER TABLE `boxing-quest-1234-2005.sample_dataset.data_cleaning`
ADD COLUMN IF NOT EXISTS PropertySplitAddress STRING,
ADD COLUMN IF NOT EXISTS PropertySplitCity STRING;

UPDATE `boxing-quest-1234-2005.sample_dataset.data_cleaning`
SET PropertySplitAddress = TRIM(
    IF(
        STRPOS(PropertyAddress, ',') > 0,
        SUBSTR(PropertyAddress, 1, STRPOS(PropertyAddress, ',') - 1),
        PropertyAddress 
    )
),
PropertySplitCity = TRIM(REGEXP_EXTRACT(PropertyAddress, r'[^,]+$'))
WHERE PropertyAddress IS NOT NULL;

-- Step 6: Example Modification for OwnerAddress (Splitting State Code from Address)
SELECT 
  REGEXP_REPLACE(OwnerAddress, r'^.*,\s*([A-Z]{2})$', r'\1') AS ModifiedAddress1
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning`;

-- Step 7: Add and Update New OwnerSplitState Column
ALTER TABLE `boxing-quest-1234-2005.sample_dataset.data_cleaning`
ADD COLUMN IF NOT EXISTS NewOwnerSplitState STRING;

UPDATE `boxing-quest-1234-2005.sample_dataset.data_cleaning`
SET NewOwnerSplitState = 'TN'
WHERE TRUE;

-- Step 8: Change 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant Column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning`
GROUP BY SoldAsVacant
ORDER BY 2;

UPDATE `boxing-quest-1234-2005.sample_dataset.data_cleaning`
SET SoldAsVacant = CASE 
  WHEN SoldAsVacant = "Y" THEN "Yes"
  WHEN SoldAsVacant = "N" THEN "No"
  ELSE SoldAsVacant
END
WHERE TRUE;

-- Step 9: Identify Duplicates Based on Key Columns
SELECT *, COUNT(*) AS duplicate_count
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning`
GROUP BY UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, 
         SoldAsVacant, OwnerName, OwnerAddress, Acreage, TaxDistrict, LandValue, 
         BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath, 
         PropertySplitAddress, PropertySplitCity, NewOwnerSplitState, row_num
HAVING COUNT(*) > 1;

-- Step 10: Drop Unused Columns
ALTER TABLE `boxing-quest-1234-2005.sample_dataset.data_cleaning`
DROP COLUMN IF EXISTS OwnerAddress,
DROP COLUMN IF EXISTS TaxDistrict,
DROP COLUMN IF EXISTS PropertyAddress;

-- Step 11: View Final Updated Data
SELECT * 
FROM `boxing-quest-1234-2005.sample_dataset.data_cleaning`;