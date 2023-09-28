SELECT *
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT *
FROM PortfolioProject..CovidDeath
ORDER BY 2,3

--SELECT *
--FROM PortfolioProject..CovidVaccination
--ORDER BY 3, 4

--Select the data we are going to be using
SELECT Location,date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeath
ORDER BY 1, 2

--looking at total cases vs total deaths
--Percentage of dying infected Covid in Malaysia
Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..CovidDeath
WHERE location LIKE 'Malaysia'
ORDER BY 1,2

--Looking at total cases vs population
--Percentage of population infected by Covid
Select location, date, total_cases, population, 
(NULLIF(CONVERT(float, total_cases), 0)/ population) * 100 AS Covidpercentage
FROM PortfolioProject..CovidDeath
WHERE location LIKE 'Malaysia'
ORDER BY 1,2

--THE DAY IN MALAYSIA WHEN COVID PERCENTAGE IS HIGHEST
SELECT
    location,
    MAX(date) AS date,
    MAX(Covidpercentage) AS MaxCovidPercentage
FROM (
    SELECT
        location,
        date,
        total_cases,
        population,
        (NULLIF(CONVERT(float, total_cases), 0) / population) * 100 AS Covidpercentage
    FROM PortfolioProject..CovidDeath
    WHERE location LIKE 'MALAYSIA'
) sub
GROUP BY location;

--Looking at countries with highest infection rates compared to population
Select location, population, MAX(total_cases) HighestInfectionCount,
MAX(total_cases/ population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeath
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Showing Countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

--BY CONTINENT
SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent IS NULL AND location NOT IN ('Upper middle income', 'Lower middle income', 'High income', 'Low income')
GROUP BY location
ORDER BY 2 DESC

--SHOW CONTINENT WITH THE HIGHEST DEATH COUNT PER POPULATION
SELECT continent, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

--GLOBAL NEW CASES BY DATE
SELECT date, SUM(new_cases) AS TotalNewCasesByDate
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 2 DESC

--GLOBAL TOTAL DEATH BY DATE
SELECT date, SUM(CONVERT(float,total_deaths)) AS TotalDeathsByDate
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 2 DESC

--GLOBAL NEW DEATH COMPARED TO NEW CASES BY DATE
SELECT date, SUM(new_cases) AS TotalNewCasesByDate, SUM(CONVERT(float, new_deaths)) AS TotalNewDeathByDate, SUM(NULLIF(CONVERT(float, new_deaths), 0))/SUM(NULLIF(new_cases, 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS TotalNewCasesByDate, SUM(CONVERT(float, new_deaths)) AS TotalNewDeathByDate, SUM(NULLIF(CONVERT(float, new_deaths), 0))/SUM(NULLIF(new_cases, 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY 1,2

--COVID VACCINATION
SELECT *
FROM PortfolioProject..CovidVaccination

--JOIN -- LOOKING AT Total Population VS Vaccinations IN MALAYSIA
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidVaccination vac
JOIN PortfolioProject..CovidDeath dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE 'Malaysia'
ORDER BY 2,3

--RUNNING TOTAL OF NEW VACCINATIONS IN MALAYSIA
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVaccinationRunningTotal
FROM PortfolioProject..CovidVaccination vac
JOIN PortfolioProject..CovidDeath dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE 'Malaysia'
ORDER BY 2,3

--RUNING TOTAL OF NEW VACCINATION COMPARED TO POPULATION IN MALAYSIA WITH CTE/SUBQUERIES
WITH VacVsPop AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVaccinationRunningTotal
FROM PortfolioProject..CovidVaccination vac
JOIN PortfolioProject..CovidDeath dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE 'Malaysia')

SELECT continent, location, date, population, NewVaccinationRunningTotal, NewVaccinationRunningTotal/population * 100 AS VaccinationPercentage
FROM VacVsPop

--RECREATE TEMP TABLE
CREATE TABLE  PercentPopulationCreated
(continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population INT,
new_vaccinations INT,
NewVaccinationRunningTotal INT);

INSERT INTO PercentPopulationCreated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVaccinationRunningTotal
FROM PortfolioProject..CovidVaccination vac
JOIN PortfolioProject..CovidDeath dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE 'Malaysia'

SELECT continent, location, date, population, NewVaccinationRunningTotal, NewVaccinationRunningTotal/population * 100 AS VaccinationPercentage
FROM PercentPopulationCreated

--CREATE VIEW TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW PercentPopulationVaccination AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS NewVaccinationRunningTotal
FROM PortfolioProject..CovidVaccination vac
JOIN PortfolioProject..CovidDeath dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE 'Malaysia'