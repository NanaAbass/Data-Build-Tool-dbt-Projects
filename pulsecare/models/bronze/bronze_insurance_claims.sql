SELECT 
    *
FROM    
    {{ source('raw', 'insurance_claims') }}