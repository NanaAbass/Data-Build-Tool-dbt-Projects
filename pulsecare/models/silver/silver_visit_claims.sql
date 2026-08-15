WITH claims AS (
    SELECT *
    FROM {{ ref("bronze_insurance_claims") }}
),

visits AS (
    SELECT *
    FROM {{ ref("bronze_patient_visits") }}
),

providers AS (
    SELECT *
    FROM {{ ref("bronze_providers") }}
),

regions AS (
    SELECT * 
    FROM {{ ref('bronze_region_lookup') }}
)

SELECT 
    v.visit_id,
    v.patient_id,
    p.provider_id,
    p.provider_name,
    p.specialty,
    v.region_id,
    r.region_name,
    r.state,
    r.timezone,
    r.network_tier,
    v.visit_date,
    v.visit_type,
    c.claim_id,
    c.payer_name,
    c.claim_status,
    c.paid_amount,
    c.billed_amount,
    c.discount_amount,
    c.claim_date

FROM claims c
LEFT JOIN visits v 
ON c.visit_id = v.visit_id
LEFT JOIN providers  p 
ON v.provider_id = p.provider_id
LEFT JOIN regions r
ON v.region_id = r.region_id
