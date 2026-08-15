WITH claims AS (
    SELECT *
    FROM {{ ref('bronze_insurance_claims') }}
),

visits AS (
    SELECT *
    FROM {{ ref('silver_patient_visits') }}
),

claims_joined AS (
    SELECT
        c.claim_id,
        c.visit_id,
        v.provider_id,
        v.provider_name,
        v.specialty,
        v.region_id,
        v.region_name,
        v.network_tier,
        v.visit_date,
        c.payer_name,
        c.billed_amount,
        c.allowed_amount,
        c.paid_amount,
        c.discount_amount,
        c.claim_status,
        c.claim_date,
        (c.claim_status = 'Denied')          AS is_denied,
        (c.billed_amount - c.discount_amount) AS net_expected_amount
    FROM claims AS c
    LEFT JOIN visits AS v
    ON c.visit_id = v.visit_id
)

SELECT *
FROM claims_joined