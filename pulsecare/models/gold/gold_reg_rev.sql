WITH claims AS (
    SELECT * 
    FROM {{ ref('silver_claims') }}
),

monthly AS (
    SELECT
        region_id,
        region_name,
        network_tier,
        DATE_TRUNC('month', CAST(visit_date AS DATE)) AS revenue_month,

        COUNT(DISTINCT visit_id)   AS visit_count,
        COUNT(*)                   AS claim_count,
        SUM(billed_amount)         AS total_billed,
        SUM(allowed_amount)        AS total_allowed,
        SUM(paid_amount)           AS total_paid,
        SUM(discount_amount)       AS total_discount,
        SUM(CASE WHEN is_denied THEN 1 ELSE 0 END) AS denied_claims

    FROM claims
    GROUP BY 1, 2, 3, 4
)

SELECT 
    *,
    CASE WHEN total_billed = 0 THEN 0
         ELSE ROUND(total_paid / total_billed, 4)
    END AS collection_rate
FROM monthly
ORDER BY revenue_month, region_name