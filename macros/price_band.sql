{# Price bands used by fct_books. One place to change the thresholds. #}
{% macro price_band(column_name, budget_below=20, standard_below=40) %}
    case
        when {{ column_name }} < {{ budget_below }} then 'budget'
        when {{ column_name }} < {{ standard_below }} then 'standard'
        else 'premium'
    end
{% endmacro %}
