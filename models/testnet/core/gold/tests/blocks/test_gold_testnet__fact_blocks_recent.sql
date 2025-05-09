{{ config (
    materialized = "view",
    tags = ['recent_test']
) }}

SELECT
    *
FROM
    {{ ref('testnet__fact_blocks') }}
WHERE
    block_number > (
        SELECT
            block_number
        FROM
            {{ ref('_testnet_block_lookback') }}
    )
