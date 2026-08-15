WITH providers AS (
    SELECT *
    FROM {{ ref("bronze_providers") }}
),

regions AS (
    SELECT *
    FROM {{ ref("bronze_region_lookup") }}
)

SELECT 
    p.provider_id,
    p.provider_name,
    p.specialty,
    r.region_id,
    r.region_name,
    r.state,
    r.network_tier,
    p.npi_number
FROM 
    providers p 
LEFT JOIN 
    regions r 
ON p.region_id = r.region_id