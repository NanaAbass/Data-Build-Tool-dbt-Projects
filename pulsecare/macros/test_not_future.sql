{% test not_future_date(model, column_name) %}

SELECT
    *
FROM {{ model }}
WHERE CAST({{ column_name }} AS DATE) > current_date

{% endtest %}