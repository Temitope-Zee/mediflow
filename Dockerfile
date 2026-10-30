FROM apache/airflow:3.3.2

# dbt gets its own virtual environment so its libraries don't clash with Airflow's
USER root
RUN python -m venv /opt/dbt_venv && \
    /opt/dbt_venv/bin/pip install --no-cache-dir dbt-postgres

# Libraries for the data generator and loader scripts
USER airflow
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" faker pandas psycopg2-binary
