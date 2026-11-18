-- PASSOLIVRE | 06 - VALIDACAO DE INTEGRIDADE DO STAR SCHEMA
-- Executar apos 04_modelo_dimensional.sql.
-- Esperado para a amostra atual: cinco indicadores iguais a zero.

SELECT
    (
        SELECT COUNT(*) - COUNT(DISTINCT id_tipo)
        FROM workspace.gs.dim_tipo_barreira
    ) AS tipos_duplicados,
    (
        SELECT COUNT(*) - COUNT(DISTINCT id_localizacao)
        FROM workspace.gs.dim_localizacao
    ) AS localizacoes_duplicadas,
    (
        SELECT COUNT(*) - COUNT(DISTINCT id_ocorrencia)
        FROM workspace.gs.fato_ocorrencias
    ) AS ocorrencias_duplicadas,
    (
        SELECT COUNT(*)
        FROM workspace.gs.fato_ocorrencias AS f
        LEFT JOIN workspace.gs.dim_tipo_barreira AS t
            ON f.id_tipo = t.id_tipo
        WHERE t.id_tipo IS NULL
    ) AS tipos_sem_correspondencia,
    (
        SELECT COUNT(*)
        FROM workspace.gs.fato_ocorrencias AS f
        LEFT JOIN workspace.gs.dim_localizacao AS l
            ON f.id_localizacao = l.id_localizacao
        WHERE l.id_localizacao IS NULL
    ) AS localizacoes_sem_correspondencia;
