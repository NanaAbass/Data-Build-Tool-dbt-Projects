WITH claims AS (
    SELECT * 
    FROM {{ ref('silver_claims') }}
),

visits AS (
    SELECT * 
    FROM {{ ref('silver_patient_visits') }}
),

visit_aggregated AS (
    SELECT
        provider_id,
        COUNT(*) AS total_visits,
        SUM(CASE WHEN visit_status = 'Completed' THEN 1 ELSE 0 END) AS completed_visits,
        SUM(CASE WHEN visit_status = 'No-Show' THEN 1 ELSE 0 END) AS no_show_visits,
        SUM(CASE WHEN visit_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_visits
    FROM visits
    GROUP BY provider_id
),

claim_aggregated AS (
    SELECT
        provider_id,
        COUNT(*) AS total_claims,
        SUM(billed_amount) AS total_billed,
        SUM(allowed_amount) AS total_allowed,
        SUM(paid_amount) AS total_paid,
        SUM(discount_amount) AS total_discount,
        SUM(CASE WHEN is_denied THEN 1 ELSE 0 END) AS denied_claims
    FROM claims
    GROUP BY provider_id
),

final_agg AS (
    SELECT
        v.provider_id,
        v.provider_name,
        v.specialty,
        v.region_id,
        v.region_name,
        v.network_tier,
        COALESCE(va.total_visits, 0) AS total_visits,
        COALESCE(va.completed_visits, 0) AS completed_visits,
        COALESCE(va.no_show_visits, 0) AS no_show_visits,
        COALESCE(va.cancelled_visits, 0) AS cancelled_visits,
        COALESCE(ca.total_claims, 0) AS total_claims,
        COALESCE(ca.total_billed, 0) AS total_billed,
        COALESCE(ca.total_allowed, 0) AS total_allowed,
        COALESCE(ca.total_paid, 0) AS total_paid,
        COALESCE(ca.total_discount, 0) AS total_discount,
        COALESCE(ca.denied_claims, 0) AS denied_claims,

        CASE WHEN COALESCE(ca.total_claims, 0) = 0 THEN 0 ELSE ROUND(ca.denied_claims * 1.0 / ca.total_claims, 4) END AS denial_rate,
        CASE WHEN COALESCE(va.completed_visits, 0) = 0 THEN 0 ELSE ROUND(ca.total_paid / va.completed_visits, 2) END AS average_rev_per_visit,
    FROM visits v
    LEFT JOIN visit_aggregated va ON v.provider_id = va.provider_id
    LEFT JOIN claim_aggregated ca ON v.provider_id = ca.provider_id
)

SELECT *
FROM final_agg
