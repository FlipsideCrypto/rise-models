-- depends_on: {{ ref('bronze_testnet__transactions') }}
{{ config (
    materialized = "incremental",
    incremental_strategy = 'delete+insert',
    unique_key = "block_number",
    cluster_by = ['modified_timestamp::DATE','partition_key'],
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION on equality(block_number)",
    tags = ['silver_testnet']
) }}

WITH bronze_transactions AS (
    SELECT 
        block_number,
        partition_key,
        VALUE :array_index :: INT AS tx_position,
        DATA AS transaction_json,
        _inserted_timestamp
    FROM 
    {% if is_incremental() %}
    {{ ref('bronze_testnet__transactions') }}
    WHERE _inserted_timestamp >= (
        SELECT 
            COALESCE(MAX(_inserted_timestamp), '1900-01-01'::TIMESTAMP) AS _inserted_timestamp
        FROM {{ this }}
    ) AND DATA IS NOT NULL
    {% else %}
    {{ ref('bronze_testnet__transactions_fr') }}
    WHERE DATA IS NOT NULL
    {% endif %}
)

SELECT 
    block_number,
    partition_key,
    tx_position,
    transaction_json,
    _inserted_timestamp,
    {{ dbt_utils.generate_surrogate_key(['block_number','tx_position']) }} AS transactions_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM bronze_transactions
where tx_position is not null
QUALIFY ROW_NUMBER() OVER (PARTITION BY transactions_id ORDER BY _inserted_timestamp DESC) = 1