WITH region_lookup_source AS (
    SELECT *
    FROM {{ source('raw', 'region_lookup') }}
)

SELECT 
    region_id,region_name,
    state,timezone,network_tier
FROM 
   region_lookup_source