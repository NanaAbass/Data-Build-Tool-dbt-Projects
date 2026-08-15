{% macro network_tier(tier_column) %}

{% set tier_map = {
    'Tier 1': 1,
    'Tier 2': 2,
    'Tier 3': 3
} %}

case
    {% for tier_key, tier_value in tier_map.items() %}
    when {{ tier_column }} = '{{ tier_key }}' then {{ tier_value }}
    {% endfor %}
    else 00
end

{% endmacro %}