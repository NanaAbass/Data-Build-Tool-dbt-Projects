WITH visits AS (
    SELECT * 
    FROM {{ ref('bronze_patient_visits') }}
),

providers AS (
    SELECT *
    FROM {{ ref('silver_providers') }}
),

visits_joined AS (
    SELECT
        v.visit_id,
        v.patient_id,
        v.provider_id,
        p.provider_name,
        p.specialty,
        p.npi_number,
        p.region_id,
        p.region_name,
        p.state,
        p.timezone,
        p.network_tier,
        v.visit_date,
        v.visit_type,
        v.diagnosis_code,
        v.visit_status,
        v.created_at
    FROM visits v 
    LEFT JOIN providers p 
    ON v.provider_id = p.provider_id
)

SELECT * 
FROM visits_joined
