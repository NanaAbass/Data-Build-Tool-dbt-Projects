SELECT 
    *
FROM    
    {{ source('raw', 'patient_visits') }}