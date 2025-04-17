{{ config (
    materialized = 'view',
    tags = ['bronze_core']
) }}

SELECT
    *
FROM
    {{ ref('bronze_testnet__blocks_fr_v2') }}
UNION ALL
SELECT
    *
FROM
    {{ ref('bronze_testnet__blocks_fr_v1') }}
