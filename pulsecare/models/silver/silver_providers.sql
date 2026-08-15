WITH providers AS (
    SELECT * FROM {{ ref('bronze_providers') }}
),

lookup AS (
    SELECT * FROM {{ ref('region_lookup') }}  
),

joined_pr AS (
    SELECT
        p.provider_id,
        p.provider_name,
        p.specialty,
        p.npi_number,
        p.region_id,
        l.region_name,
        l.state,
        l.timezone,
        l.network_tier,
        p.hire_date,
        p.active_flag
    FROM providers AS p
    LEFT JOIN lookup AS l
    ON p.region_id = l.region_id
)


SELECT *
FROM
    joined_pr