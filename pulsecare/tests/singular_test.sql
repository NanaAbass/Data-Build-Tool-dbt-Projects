{#
This test is set for the data quality checks on the billed amount and discount amount.
The discount amount should not be greater than the billed amount.
#}

SELECT 
    claim_id,
    visit_id,
    provider_id,
    billed_amount,
    discount_amount,
    net_expected_amount
FROM
    {{ ref("silver_claims") }}
WHERE billed_amount < discount_amount