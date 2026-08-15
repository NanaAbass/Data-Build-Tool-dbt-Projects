{% macro net_revenue(paid_column, discount_column, currency_vars='exchange_rate_to_local')%}

    round(
        ( {{ paid_column }} * {{ var(currency_vars) }} )
        - {{ discount_column }}, 2
    )

{% endmacro %}

