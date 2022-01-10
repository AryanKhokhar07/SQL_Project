/*
COVID-19 Data Exploration 

Main Clauses/Functions/Skills Used: Order By, Group By, Inner Join, CTE, Temp Table, Creating View
*/



SELECT *
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4



--Selecting out the data that we'll be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY location, date



--Total Cases v/s Total Deaths
--Shows likelihood of dying of covid in case you're infected
-- (You can also view the data for any specific country, like India in my case)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
--WHERE location = 'India'
ORDER BY location, date



--Total Cases v/s Total Population
--Showing what percentage of population got infected by covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
--WHERE location = 'India'
ORDER BY location, date



--Countries with highest infection rate copmared to population

SELECT location, population, MAX(total_cases) AS max_infection_count, 
	MAX((total_cases/population))*100 AS percent_population_infected
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC



--Showing countries with highest death count

SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY total_death_count DESC



--Showing continents with highest Covid deaths 

SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM CovidProject..CovidDeaths
WHERE continent is NULL
	AND location <> 'High Income' AND location <> 'Upper middle income'
	AND location <> 'Lower middle income' AND location <> 'Low income'
	AND location <> 'International'
GROUP BY location
ORDER BY total_death_count DESC




--GLOBAL NUMBERS
--Global death percentage on each day

SELECT date, SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS int)) AS Total_Deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY date, Total_Cases



--Overall global death percentage

SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS int)) AS Total_Deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
FROM CovidProject..CovidDeaths
WHERE continent is NOT NULL




--Total Population v/s Vaccinations

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS cumulative_vaccination
FROM CovidProject..CovidDeaths AS death
INNER JOIN CovidProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is NOT NULL
ORDER BY location, date



--Using CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, 
	cumulative_vaccination)
AS
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS cumulative_vaccination
FROM CovidProject..CovidDeaths AS death
INNER JOIN CovidProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is NOT NULL
--ORDER BY location, date
)
SELECT *, (cumulative_vaccination/population)*100 percent_vaccinated
FROM PopvsVac
ORDER BY location, date



--Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccination numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS cumulative_vaccination
FROM CovidProject..CovidDeaths AS death
INNER JOIN CovidProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is NOT NULL
--ORDER BY location, date

SELECT *, (cumulative_vaccination/population)*100 percent_vaccinated
FROM #PercentPopulationVaccinated
ORDER BY location, date




--Creating View to store data for later visualistaion

CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY 
	death.location, death.date) AS cumulative_vaccination
FROM CovidProject..CovidDeaths AS death
INNER JOIN CovidProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent is NOT NULL
--ORDER BY location, date


--Viewing the data that we stored for visualisation
SELECT *
FROM PercentPopulationVaccinated
ORDER BY location, date
