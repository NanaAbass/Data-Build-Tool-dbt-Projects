{% test val_within_range(model, column_name, min_value=none, max_value=none) %}

{% if min_value is none and max_value is none %}

    {{ exceptions.raise_compiler_error(
        "Val_within_range requires at least one of min_value or max_value"
    ) }}
{% endif %}

SELECT *
FROM {{ model }}
WHERE 
    {{ column_name }} IS NOT NULL
AND (
        {% if min_value is not none %}
        {{ column_name }} < {{ min_value }}
        {% endif %}

        {% if min_value is not none or max_value is not none %}
        or 
        {% endif %}

        {% if max_value is not none %}
        {{ column_name }} > {{ max_value }}
        {% endif %}

    )

{% endtest %}
