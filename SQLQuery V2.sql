

SELECT location, date, population, 
       (TRY_CONVERT(decimal(18, 2), total_deaths) / TRY_CONVERT(decimal(18, 2), total_cases))*100 AS case_death_ratio
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'


--SELECT* 
--fROM PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using

	--select location, date, total_cases, new_cases, total_deaths, population
	--from PortfolioProject.dbo.CovidDeaths
	--order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood dying if you contract covid in your country
select location, date, total_cases, total_deaths, 
(TRY_CONVERT(decimal(18, 2), total_deaths) / TRY_CONVERT(decimal(18, 2), total_cases))*100 AS DeathPercentage
from PortfolioProject.dbo.CovidDeaths
Where location like '%states%'
order by 1,2

---Looking Total Cases vs Population
-- Shows what percentage of population got Covid
select location, date, population, total_cases, 
(TRY_CONVERT(decimal(18, 2), total_cases) / TRY_CONVERT(decimal(18, 2), population))*100 AS PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
Where location like '%states%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

select location, population, MAX(total_cases) as HighestInfectionCount, 
MAX(TRY_CONVERT(decimal(18, 2), total_cases) / TRY_CONVERT(decimal(18, 2), population))*100 AS PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population

select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continent with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUBERS

SELECT
  --date,
  SUM(new_cases) as total_cases,
  SUM(cast(new_deaths as int)) as total_deaths,
  CASE WHEN SUM(new_cases) <> 0
       THEN SUM(cast(new_deaths as int))/SUM(new_cases)*100
       ELSE NULL
  END as DeathPercentage
FROM
  PortfolioProject.dbo.CovidDeaths
WHERE
  continent IS NOT NULL
--GROUP BY
--  date
ORDER BY
  1,2;


-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2, 3

--USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)
Select*, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric, 
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)
Select*, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Creating View to store data for later visualization

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, 
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3