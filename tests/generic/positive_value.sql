{# Generic test: fails for every row where the column is zero or negative (nulls are left to not_null). #}
{% test positive_value(model, column_name) %}
select {{ column_name }}
from {{ model }}
where {{ column_name }} <= 0
{% endtest %}
