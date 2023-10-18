

SELECT * FROM noc_regions
SELECT * FROM athlete_events

--How many olympics games have been held?

SELECT COUNT(DISTINCT Games) AS total_olympic_games FROM athlete_events

--2. List down all Olympics games held so far.

SELECT Year,Season,city FROM athlete_events


--3. Mention the total no of nations who participated in each olympics game?

SELECT games, count (distinct region ) AS total_country FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC
GROUP BY games

--4. Which year saw the highest and lowest no of countries participating in olympics?

WITH CTE AS
(SELECT games, count (distinct region ) AS total_country FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC
GROUP BY games)
,CTE1 AS(
SELECT *, RANK() OVER (ORDER BY total_country) rn1, RANK() OVER (ORDER BY total_country DESC) rn2  FROM CTE)
,CTE2 AS(
SELECT rn1,CONCAT(games,'-',total_country) AS lowest_country
FROM CTE1
WHERE rn1=1)
, CTE3 AS(
SELECT  rn2,CONCAT(games,'-',total_country) AS highest_country
FROM CTE1
WHERE rn2=1)
SELECT lowest_country,highest_country  FROM CTE2 JOIN CTE3 ON CTE2.rn1 = CTE3.rn2

--OPTION - 2
 with all_countries as
 (select games, nr.region
 from athlete_events oh
 join noc_regions nr ON nr.noc=oh.noc
 group by games, nr.region)
 , tot_countries as(
 select games, count(1) as total_countries
 from all_countries
 group by games)
select DISTINCT concat(first_value(games) over(order by total_countries) , ' - ', first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
concat(first_value(games) over(order by total_countries desc), ' - ', first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
from tot_countries order by 1;


--5. Which nation has participated in all of the olympic games?
SELECT * FROM noc_regions
SELECT * FROM athlete_events

WITH CTE AS(
SELECT games, region  FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC
)
,CTE1 AS(
SELECT games, region, COUNT (DISTINCT region) AS xx FROM CTE
GROUP BY games, region
)
SELECT region, COUNT(region) AS total_participated_games FROM CTE1
GROUP BY  region
HAVING COUNT(region) = (SELECT COUNT(DISTINCT Games) FROM athlete_events)

--6. Identify the sport which was played in all summer olympics.
WITH CTE AS(
SELECT DISTINCT games, Sport, COUNT( DISTINCT Sport) AS XXX FROM athlete_events
WHERE games LIKE '%Summer%'
GROUP BY games,Sport
)
SELECT Sport, COUNT(XXX) AS no_of_games, COUNT(Sport) AS Total_games FROM CTE
GROUP BY Sport
HAVING COUNT(XXX) = (SELECT COUNT(DISTINCT games) FROM athlete_events
WHERE games LIKE '%Summer%')

--7. Which Sports were just played only once in the olympics?
WITH CTE AS(
SELECT DISTINCT games, Sport, COUNT( DISTINCT Sport) AS XXX FROM athlete_events
GROUP BY games,Sport
)
,CTE1 AS(
SELECT sport ,COUNT(*) AS XXX FROM CTE
GROUP BY sport
HAVING COUNT(*) = 1)
SELECT CTE1.sport,CTE1.XXX,CTE.games
FROM CTE1 INNER JOIN CTE 
ON CTE.sport = CTE1.sport AND CTE.XXX = CTE1.XXX
ORDER BY CTE1.sport

--8. Fetch the total no of sports played in each olympic games.

WITH CTE AS(
SELECT DISTINCT games, Sport, COUNT( DISTINCT Sport) AS XXX FROM athlete_events
GROUP BY games,Sport
)
SELECT games ,COUNT(*) AS XXX FROM CTE
GROUP BY games
order by 2 DESC,games 


--9. Fetch details of the oldest athletes to win a gold medal.
 with temp as
 (select name,sex,cast(case when age = 'NA' then '0' else age end as int) as age
 ,team,games,city,sport, event, medal
  from athlete_events),
  ranking as
            (select *, rank() over(order by age desc) as rnk
            from temp
            where medal='Gold')
    select *
    from ranking
    where rnk = 1;

--10.Find the Ratio of male and female athletes participated in all olympic games.
WITH CTE AS(
SELECT COUNT (sex) AS MMM FROM athlete_events
WHERE sex = 'M')
,CTE1 AS(
SELECT COUNT (sex) AS FFF FROM athlete_events
WHERE sex = 'F')SELECT CONCAT(1,':', CAST(1.00*MMM/FFF AS DECIMAL (10,2))) AS ratio FROM CTE ,CTE1

--11.Fetch the top 5 athletes who have won the most gold medals.
with CTE as
(select name, team, count(1) as total_gold_medals
from  athlete_events
where medal = 'Gold'
group by name, team),
CTE1 as
(select *, dense_rank() over (order by total_gold_medals desc) as rnk
from CTE)
select name, team, total_gold_medals from CTE1 where rnk <= 5;


--12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with CTE as
(select name, team, count(1) as total_gold_medals
from  athlete_events
where medal = 'Gold' OR medal = 'silver' OR medal = 'bronze'
group by name, team),
CTE1 as
(select *, dense_rank() over (order by total_gold_medals desc) as rnk from CTE)
select name, team, total_gold_medals from CTE1 where rnk <= 5;

--13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
WITH CTE AS
(SELECT region, SUM(CASE WHEN Medal = 'Gold' THEN 1 WHEN Medal = 'silver' THEN 1 WHEN Medal =  'bronze' THEN 1 ELSE 0 END ) as xxx
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY region)
,CTE1 AS(
SELECT *, DENSE_RANK() OVER (ORDER BY XXX DESC) Rnk FROM CTE)
SELECT * FROM CTE1 WHERE Rnk<=5


--14.List down total gold, silver and broze medals won by each country.
SELECT region, 
SUM(CASE WHEN Medal = 'Gold' THEN 1  ELSE 0 END ) AS Gold,
SUM(CASE WHEN Medal = 'silver' THEN 1 ELSE 0 END ) AS silver,
SUM(CASE WHEN Medal =  'bronze' THEN 1 ELSE 0 END ) as Bronze
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY region ORDER BY 2 DESC


--15.List down total gold, silver and broze medals won by each country corresponding to each olympic games.
SELECT games,region, 
SUM(CASE WHEN Medal = 'Gold' THEN 1  ELSE 0 END ) AS Gold,
SUM(CASE WHEN Medal = 'silver' THEN 1 ELSE 0 END ) AS silver,
SUM(CASE WHEN Medal =  'bronze' THEN 1 ELSE 0 END ) as Bronze
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region ORDER BY 1 

--16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH gold AS(
SELECT games,CONCAT(region,'-', 
SUM(CASE WHEN Medal = 'Gold' THEN 1  ELSE 0 END )) AS Max_Gold , DENSE_RANK() OVER (PARTITION BY Games ORDER BY (SUM(CASE WHEN Medal = 'Gold' THEN 1  ELSE 0 END )) DESC) AS G
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region  )
,max_gold AS(
SELECT games,Max_Gold FROM gold WHERE G = 1)
,silver AS(
SELECT games,CONCAT(region,'-', 
SUM(CASE WHEN Medal = 'silver' THEN 1  ELSE 0 END )) AS Max_silver , DENSE_RANK() OVER (PARTITION BY Games ORDER BY (SUM(CASE WHEN Medal = 'silver' THEN 1  ELSE 0 END )) DESC) AS S
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region  )
,max_silver AS(
SELECT games,Max_silver FROM silver WHERE S = 1)
,bronze AS(
SELECT games,CONCAT(region,'-', 
SUM(CASE WHEN Medal = 'bronze' THEN 1  ELSE 0 END )) AS Max_bronze , DENSE_RANK() OVER (PARTITION BY Games ORDER BY (SUM(CASE WHEN Medal = 'bronze' THEN 1  ELSE 0 END )) DESC) AS B
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region  )
,max_bronze AS(
SELECT games,Max_bronze FROM bronze WHERE B = 1)
SELECT A.games,A.Max_Gold,B.Max_silver,C.Max_bronze FROM max_gold A , Max_silver B,Max_bronze C 
WHERE A.games = B.games AND A.games = C.games



--17.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH gold AS(
SELECT games,CONCAT(region,'-', 
SUM(CASE WHEN Medal = 'Gold' THEN 1  ELSE 0 END )) AS Max_Gold , DENSE_RANK() OVER (PARTITION BY Games ORDER BY (SUM(CASE WHEN Medal = 'Gold' THEN 1  ELSE 0 END )) DESC) AS G
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region  )
,max_gold AS(
SELECT games,Max_Gold FROM gold WHERE G = 1)
,silver AS(
SELECT games,CONCAT(region,'-', 
SUM(CASE WHEN Medal = 'silver' THEN 1  ELSE 0 END )) AS Max_silver , DENSE_RANK() OVER (PARTITION BY Games ORDER BY (SUM(CASE WHEN Medal = 'silver' THEN 1  ELSE 0 END )) DESC) AS S
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region  )
,max_silver AS(
SELECT games,Max_silver FROM silver WHERE S = 1)
,bronze AS(
SELECT games,CONCAT(region,'-', 
SUM(CASE WHEN Medal = 'bronze' THEN 1  ELSE 0 END )) AS Max_bronze , DENSE_RANK() OVER (PARTITION BY Games ORDER BY (SUM(CASE WHEN Medal = 'bronze' THEN 1  ELSE 0 END )) DESC) AS B
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region  )
,max_bronze AS(
SELECT games,Max_bronze FROM bronze WHERE B = 1)
, M_medals AS(
SELECT games,CONCAT(region,'-', 
SUM(CASE WHEN Medal <> 'NA' THEN 1  ELSE 0 END )) AS Max_Medals, DENSE_RANK() OVER (PARTITION BY Games ORDER BY (SUM(CASE WHEN Medal <> 'NA' THEN 1  ELSE 0 END )) DESC) AS X
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY games, region  )
,max_Medals AS(
SELECT games,Max_Medals FROM M_medals WHERE X = 1)

SELECT A.games,A.Max_Gold,B.Max_silver,C.Max_bronze,D.Max_Medals FROM max_gold A , Max_silver B,Max_bronze C, max_Medals D
WHERE A.games = B.games AND A.games = C.games AND A.games = D.games

--18.Which countries have never won gold medal but have won silver/bronze medals?
WITH CTE AS (
SELECT region, 
COUNT(CASE WHEN Medal = 'Gold' THEN 1  ELSE null END ) AS Gold,
COUNT(CASE WHEN Medal = 'silver' THEN 1 ELSE null END ) AS silver,
COUNT(CASE WHEN Medal =  'bronze' THEN 1 ELSE null END ) as Bronze
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC 
GROUP BY region )
SELECT region, SUM(gold) AS gold, SUM(silver) AS silver, SUM(Bronze) AS bronze FROM CTE
WHERE Gold = 0 AND (silver <> 0 OR bronze <> 0)
GROUP BY region

--19.In which Sport/event, India has won highest medals.
WITH CTE AS
(SELECT region,Sport, SUM(CASE WHEN Medal = 'Gold' THEN 1 WHEN Medal = 'silver' THEN 1 WHEN Medal =  'bronze' THEN 1 ELSE 0 END ) as xxx
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC GROUP BY region,Sport)

SELECT TOP 1 sport, xxx AS Total_medals FROM CTE
where region = 'India'
ORDER BY XXX DESC

--20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
SELECT region AS team,Sport , Games, SUM(CASE WHEN Medal <> 'NA' THEN 1 ELSE 0 END ) as Medal
FROM athlete_events A INNER JOIN noc_regions B ON A.NOC = B.NOC 
WHERE region = 'India' AND sport = 'Hockey' GROUP BY region,Sport,Games ORDER by 4 DESC



