-- OpenWebUI settings analysis in PostgreSQL database
-- Script for retrieving configuration data

-- 1. Get all settings from config table
\echo '=== OPENWEBUI SETTINGS ==='
SELECT
    id as setting_key,
    CASE
        WHEN LENGTH(data::text) > 100 THEN LEFT(data::text, 100) || '...'
        ELSE data::text
    END as setting_value,
    created_at,
    updated_at
FROM config
ORDER BY id;

-- 2. Get RAG and embedding settings
\echo ''
\echo '=== RAG AND EMBEDDINGS ==='
SELECT
    id as setting_key,
    data::text as setting_value
FROM config
WHERE id LIKE '%rag%' OR id LIKE '%embedding%' OR id LIKE '%vector%'
ORDER BY id;

-- 3. Get model settings
\echo ''
\echo '=== MODEL SETTINGS ==='
SELECT
    id as setting_key,
    data::text as setting_value
FROM config
WHERE id LIKE '%model%' OR id LIKE '%ollama%' OR id LIKE '%openai%'
ORDER BY id;

-- 4. Get interface settings
\echo ''
\echo '=== INTERFACE SETTINGS ==='
SELECT
    id as setting_key,
    data::text as setting_value
FROM config
WHERE id LIKE '%ui%' OR id LIKE '%theme%' OR id LIKE '%interface%'
ORDER BY id;

-- 5. Get security settings
\echo ''
\echo '=== SECURITY SETTINGS ==='
SELECT
    id as setting_key,
    data::text as setting_value
FROM config
WHERE id LIKE '%auth%' OR id LIKE '%security%' OR id LIKE '%permission%'
ORDER BY id;

-- 6. Config table statistics
\echo ''
\echo '=== SETTINGS STATISTICS ==='
SELECT
    COUNT(*) as total_settings,
    COUNT(CASE WHEN data IS NOT NULL THEN 1 END) as configured_settings,
    COUNT(CASE WHEN data IS NULL THEN 1 END) as empty_settings,
    MIN(created_at) as first_setting_created,
    MAX(updated_at) as last_setting_updated
FROM config;

-- 7. Configuration data size
\echo ''
\echo '=== CONFIGURATION DATA SIZE ==='
SELECT
    pg_size_pretty(pg_total_relation_size('config')) as table_size,
    pg_size_pretty(pg_relation_size('config')) as data_size,
    pg_size_pretty(pg_indexes_size('config')) as index_size,
    (SELECT COUNT(*) FROM config) as record_count;

-- 8. Recent settings changes
\echo ''
\echo '=== RECENT CHANGES ==='
SELECT
    id as setting_key,
    CASE
        WHEN LENGTH(data::text) > 50 THEN LEFT(data::text, 50) || '...'
        ELSE data::text
    END as setting_value,
    updated_at
FROM config
WHERE updated_at IS NOT NULL
ORDER BY updated_at DESC
LIMIT 10;
