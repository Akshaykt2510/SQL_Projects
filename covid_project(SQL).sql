
--- Select the data	we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM project..coviddeath
ORDER BY location, date


---Looking at Total Cases vs Total Deaths

SELECT location, date, total_deaths, total_cases, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
FROM project..coviddeath
ORDER BY location, date


---Looking at Total Cases vs Population
---Shows what percentageof population got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as percentage_pop_infected
FROM project..coviddeath
ORDER BY location, date


---Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as percentage_pop_infected
FROM project..coviddeath
GROUP BY location, population
ORDER BY percentage_pop_infected desc


---Showing Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as INT)) as Total_Death_Count
FROM project..coviddeath
WHERE continent is NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC


---Lets Break things down by continent

SELECT continent, MAX(CAST(total_deaths as INT)) as Total_Death_Count
FROM project..coviddeath
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC


---Global Numbers

SELECT SUM(new_cases) as Total_cases, SUM(CAST(new_deaths as INT)) as Total_deaths, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as DeathPercentage
FROM project..coviddeath
WHERE continent is NOT NULL	
ORDER BY 1, 2


---Looking at Total Population vs Vaccination

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations as BIGINT)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Total_Vaccinated
FROM project..coviddeath as cd
JOIN project..covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date 
WHERE cd.continent is NOT NULL
ORDER BY 2, 3


--- With using CTE

With PopvsVacc(Continent, Location, Date, Population, New_Vaccinations, Total_Vaccinated)
as
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations as BIGINT)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Total_Vaccinated
FROM project..coviddeath as cd
JOIN project..covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date 
WHERE cd.continent is NOT NULL
---ORDER BY 2, 3
)
Select *, (Total_Vaccinated/Population)*100 as VaccinatedPercentage
From PopvsVacc


---Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations as BIGINT)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Total_Vaccinated
FROM project..coviddeath as cd
JOIN project..covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date 
WHERE cd.continent is NOT NULL
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 VaccinatedPercentage
From #PercentPopulationVaccinated