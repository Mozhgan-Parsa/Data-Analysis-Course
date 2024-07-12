Select *
From Covid..CovidDeaths
Where continent is not null 
order by 3,4

-- This query sums the total number of vaccinations administered in each country
-- It groups the results by country and orders them from highest to lowest total vaccinations
SELECT location, SUM(CAST(total_vaccinations AS BIGINT)) AS total_vaccinations
FROM Covid..CovidVaccinations
GROUP BY location
ORDER BY total_vaccinations DESC;




Select Location, date, total_cases, new_cases, total_deaths, population_density
From Covid..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT 
    location, 
    date, 
    CAST(total_cases AS BIGINT) AS total_cases, 
    CAST(total_deaths AS BIGINT) AS total_deaths, 
    CASE 
        WHEN CAST(total_cases AS BIGINT) = 0 THEN 0 
        ELSE (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 
    END AS DeathPercentage
FROM Covid..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL 
ORDER BY location, date;

ALTER TABLE Covid..CovidDeaths
ALTER COLUMN total_cases BIGINT;

ALTER TABLE Covid..CovidDeaths
ALTER COLUMN total_deaths BIGINT;

-- Total Cases vs population_density
-- Shows what percentage of population_density infected with Covid

Select Location, date, population_density, total_cases,  (total_cases/population_density)*100 as Percentpopulation_densityInfected
From Covid..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to population_density

Select Location, population_density, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population_density))*100 as Percentpopulation_densityInfected
From Covid..CovidDeaths
--Where location like '%states%'
Group by Location, population_density
order by Percentpopulation_densityInfected desc


-- Countries with Highest Death Count per population_density

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population_density

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

--AVG(CAST(total_vaccinations AS FLOAT)) AS avg_total_vaccinations
SELECT location, 
       DATEPART(YEAR, date) AS year, 
       DATEPART(MONTH, date) AS month,
	   AVG(CAST(total_vaccinations AS FLOAT)) AS avg_total_vaccinations
FROM Covid..CovidVaccinations
GROUP BY location, DATEPART(YEAR, date), DATEPART(MONTH, date)
ORDER BY location, year, month;



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Covid..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- Total population_density vs Vaccinations
-- Shows Percentage of population_density that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population_density)*100
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, population_density, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population_density)*100
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/population_density)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #Percentpopulation_densityVaccinated
Create Table #Percentpopulation_densityVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population_density numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #Percentpopulation_densityVaccinated
Select dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population_density)*100
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/population_density)*100
From #Percentpopulation_densityVaccinated




-- Creating View to store data for later visualizations

Create View Percentpopulation_densityVaccinated as
Select dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population_density)*100
From Covid..CovidDeaths dea
Join Covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
