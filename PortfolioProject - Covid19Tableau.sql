-- Project Dataset found at https://ourworldindata.org/covid-deaths

-- Total Covid Cases vs Total Covid Deaths with Death Percentage

SELECT SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
--WHERE Location LIKE '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2

-- Total Covid Death Count by Continent

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE Location LIKE '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE Location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Infection Rate compared to Population over Time

SELECT Location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE Location LIKE '%states%'
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC
