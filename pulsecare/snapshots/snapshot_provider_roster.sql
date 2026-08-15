{% snapshot provider_roster %}

{{
    config(
        target_schema=target.schema ~ '_snapshots',
        unique_key='provider_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select
    provider_id,
    provider_name,
    specialty,
    npi_number,
    region_id,
    hire_date,
    active_flag,
    updated_at
from {{ ref('bronze_providers') }}

{% endsnapshot %}