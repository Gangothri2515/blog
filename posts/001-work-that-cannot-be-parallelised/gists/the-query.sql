INSERT OVERWRITE TABLE staging.stg_fact_week
SELECT   t.planning_month_key,
         l.country_name,
         c.channel_name,
         v.version_name,
         i.product_name,
         t.season_name,
         SUM(CAST(s.units      AS DECIMAL(38,10))) AS units,
         SUM(CAST(s.net_amount AS DECIMAL(38,10))) AS net_amount
         -- ... eleven more SUM(CAST(... AS DECIMAL(38,10))) measures
FROM       warehouse.fact_style_week s
INNER JOIN (SELECT DISTINCT version_key, version_name FROM warehouse.dim_version) v
ON         v.version_key = s.version_key
INNER JOIN (SELECT DISTINCT location_key, country_name FROM warehouse.dim_location) l
ON         l.location_key = s.location_key
-- ... three more dimension joins
GROUP BY   t.planning_month_key, l.country_name, c.channel_name,
           v.version_name, i.product_name, t.season_name;
