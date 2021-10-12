-- SELECTING THE TOTAL NUMBER OF CITATIONS FOR EACH BOROUGH IN THE DATASET
SELECT borough as 'Borough', COUNT(violation_code) as 'Total Number of Citations'
FROM PortfolioProject..new_york_citations$
WHERE restaurant_name is not null AND violation_code is not null
GROUP BY borough
ORDER BY 'Total Number of Citations' DESC

-- SELECTING NUMBER OF CITATIONS GIVEN BASED ON RESTAURANT CUISINE TYPE
SELECT DISTINCT cuisine_description as 'Cuisine Type',COUNT(violation_code) as 'Total Number of Citations'
FROM PortfolioProject..new_york_citations$
WHERE cuisine_description is not null and violation_code is not null
GROUP BY cuisine_description
ORDER BY 'Total Number of Citations' DESC

-- SELECTING THE TOTAL NUMBER OF NOT CRITICAL FLAGS GIVEN BASED ON BOROUGH
SELECT borough as 'Borough', COUNT(critical_flag) as 'Total Number of Not Critical Flags'
FROM PortfolioProject..new_york_citations$
WHERE  critical_flag = 'Not Critical'
GROUP BY borough
ORDER BY 'Total Number of Not Critical Flags' DESC

-- SELECTING THE TOTAL NUMBER OF CRITICAL FLAGS GIVEN BASED ON BOROUGH
SELECT borough as 'Borough', COUNT(critical_flag) as 'Total Number of Critical Flags'
FROM PortfolioProject..new_york_citations$
WHERE  critical_flag = 'Critical'
GROUP BY borough
ORDER BY 'Total Number of Critical Flags' DESC

-- SELECTING THE TOTAL NUMBER OF CITATIONS GIVEN BASED ON RESTAURANT FRANCHISE
SELECT restaurant_name as 'Restaurant Franchise', count(restaurant_name) as 'Total Number of Citations'
FROM PortfolioProject..new_york_citations$
GROUP BY restaurant_name
HAVING COUNT(restaurant_name)>1
ORDER BY 'Total Number of Citations' DESC