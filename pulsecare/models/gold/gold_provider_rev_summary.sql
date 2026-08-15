WITH visit_claims AS (
    SELECT *
    FROM {{ ref("silver_visit_claims") }}
)

SELECT 
    provider_id,
    provider_name,
    specialty,
    region_id,
    {{ network_tier('network_tier') }} AS tier_priority,
    COUNT(DISTINCT visit_id) AS total_visits,
    ROUND(SUM(paid_amount), 2) AS total_paid,
    ROUND(SUM(billed_amount), 2) AS total_billed,
    ROUND(SUM(discount_amount), 2) AS total_discount,
    {{ net_revenue('SUM(paid_amount)', 'SUM(discount_amount)') }} AS revenue_realized_in_cedis
FROM 
    visit_claims
GROUP BY 1, 2, 3, 4, 5
ORDER BY 10 DESC