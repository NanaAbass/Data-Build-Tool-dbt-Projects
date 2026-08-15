WITH visit_claims AS (
    SELECT *
    FROM {{ ref("silver_visit_claims") }}
)

SELECT 
    region_id,
    region_name,
    state,
    {{ network_tier('network_tier') }} AS tier_priority,
    COUNT(DISTINCT visit_id) AS total_visits,
    ROUND(SUM(billed_amount), 2) AS total_billed,
    ROUND(SUM(paid_amount), 2) AS total_paid,
    ROUND(SUM(discount_amount), 2) AS total_discount,
    {{ net_revenue('SUM(paid_amount)', 'SUM(discount_amount)') }} AS net_revenue_realized_in_cedis
FROM 
    visit_claims
GROUP BY 1, 2, 3, 4
ORDER BY 9 DESC