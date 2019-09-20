--------------------
-- Correlation
select Correlation = (COUNT(*) * SUM(X * Y) - SUM(X) * SUM(Y)) / 
                   (SQRT(COUNT(*) * SUM(X * X) - SUM(X) * SUM(X))
                    * SQRT(COUNT(*) * SUM(Y * Y) - SUM(Y) * SUM(Y)))
FROM [Table];


--------------------
-- Slope
drop table if exists #t
create table #t (
    Date datetime,
    Keyword nchar(1),
    Score float
)

insert into #t
values ('20190801', 'a', 101), ('20190802', 'a', 102), ('20190807', 'a', 104), ('20190803', 'a', 108)

SELECT
    Scores.Date, Scores.Keyword, Scores.Score,
    (N * Sum_XY - Sum_X * Sum_Y)/(N * Sum_X2 - Sum_X * Sum_X) AS Slope
FROM #t Scores
INNER JOIN (
    SELECT
        Keyword,
        COUNT(*) AS N,
        SUM(CAST(Date as float)) AS Sum_X,
        SUM(CAST(Date as float) * CAST(Date as float)) AS Sum_X2,
        SUM(Score) AS Sum_Y,
        SUM(Score*Score) AS Sum_Y2,
        SUM(CAST(Date as float) * Score) AS Sum_XY
    FROM #t
    GROUP BY Keyword
) G ON G.Keyword = Scores.Keyword;


--------------------
--- Cumulative total and ABC analysis SKU / Region
WITH Value ([SKU], [Region], [Value]) AS
(
    -- Get the total for each SKU / Region
    SELECT
        ssd.[SKU], ssd.[Region],
        SUM(ssd.[Value]) [Value]
    FROM [Table]  ssd
    GROUP BY
    ssd.[SKU], ssd.[Region]
)
-- Calculate cumulative total and ABC
SELECT
    ps.[SKU], ps.[Region], 
    ps.[Value],
    SUM(ps.[Value]) OVER (ORDER BY ps.[Value] DESC, ps.[Region], ps.[SKU]) AS CumulativeValue,
    SUM(ps.[Value]) OVER () AS TotalValue,
    SUM(ps.[Value]) OVER (ORDER BY ps.[Value] DESC) / SUM(cast(ps.[Value] as float)) OVER () AS CumulativePercentage,
    CASE
        WHEN SUM(ps.[Value]) OVER (ORDER BY ps.[Value] DESC) / SUM(cast(ps.[Value] as float)) OVER () <= 0.7
            THEN 'A'
        WHEN SUM(ps.[Value]) OVER (ORDER BY ps.[Value] DESC) / SUM(cast(ps.[Value] as float)) OVER () <= 0.95 
            THEN 'B'
        ELSE 'C'
    END AS Class
FROM Value ps
GROUP BY
    ps.[SKU], ps.[Region],
    ps.[Value];