-- SELECTING THE TOTAL NUMBER OF OCCURENCES BY INCIDENT
SELECT primary_description as 'Incident', COUNT(primary_description) as 'Total Number of Occurences'
FROM PortfolioProject..chicago_incidents$
WHERE primary_description is not null
GROUP BY primary_description
ORDER BY 'Total Number of Occurences' DESC

-- SELECTING THE TOTAL NUMBER OF INDICENTS THAT LED TO ARREST
SELECT primary_description as 'Incident', COUNT(primary_description) as 'Total Number of Occurences'
FROM PortfolioProject..chicago_incidents$
WHERE primary_description is not null AND arrest = 'Y'
GROUP BY primary_description
ORDER BY 'Total Number of Occurences' DESC

-- SELECTING THE TOTAL NUMBER OF INDICENTS THAT DID NOT LEAD TO ARREST
SELECT primary_description as 'Incident', COUNT(primary_description) as 'Total Number of Occurences'
FROM PortfolioProject..chicago_incidents$
WHERE primary_description is not null AND arrest = 'N'
GROUP BY primary_description
ORDER BY 'Total Number of Occurences' DESC

-- SELECTING THE TOTAL NUMBER OF INCIDENTS THAT WERE DOMESTIC
SELECT primary_description as 'Incident', COUNT(domestic) as 'Domestic Incidents'
FROM PortfolioProject..chicago_incidents$
WHERE domestic is not null AND domestic = 'Y'
GROUP BY primary_description
ORDER BY 'Domestic Incidents' DESC

-- SELECTING THE TOTAL NUMBER OF INCIDENTS THAT WERE NON DOMESTIC
SELECT primary_description as 'Incident', COUNT(domestic) as 'Non Domestic Incidents'
FROM PortfolioProject..chicago_incidents$
WHERE domestic is not null AND domestic = 'N'
GROUP BY primary_description
ORDER BY 'Non Domestic Incidents' DESC