-- PASSOLIVRE | 03 - CAMADA OURO (TABELAS AGREGADAS)
-- Objetivo: disponibilizar indicadores para o painel de acessibilidade.
-- Dependencia: view workspace.gs.vw_ocorrencias_enriquecidas (02_prata.sql).
-- As tabelas abaixo sao materializadas por CREATE OR REPLACE TABLE.
-- Para atualizar os indicadores apos novas cargas, reexecutar este script.
-- Totais por bairro/tipo consideram somente APTO e ENDERECO_ENCONTRADO;
-- o resumo considera todas as ocorrencias existentes na view.
-- Dados ficticios de carater academico.

-- CAMADA OURO
-- 1. Resumo consolidado dos indicadores de acessibilidade.
-- NULLIF evita divisao por zero quando nao houver ocorrencias.

CREATE OR REPLACE TABLE workspace.gs.ouro_resumo_acessibilidade
USING DELTA AS
SELECT
    COUNT(*) AS total_ocorrencias,

    SUM(
        CASE WHEN status_qualidade = 'APTO'
        THEN 1 ELSE 0 END
    ) AS ocorrencias_aptas,

    SUM(
        CASE WHEN status_qualidade = 'PENDENTE'
        THEN 1 ELSE 0 END
    ) AS ocorrencias_pendentes,

    SUM(
        CASE WHEN status_enriquecimento = 'ENDERECO_ENCONTRADO'
        THEN 1 ELSE 0 END
    ) AS enderecos_encontrados,

    SUM(
        CASE
            WHEN status_qualidade = 'APTO'
             AND status_enriquecimento = 'ENDERECO_ENCONTRADO'
            THEN 1 ELSE 0
        END
    ) AS aptas_com_endereco,

    SUM(
        CASE WHEN status_enriquecimento = 'CEP_INVALIDO'
        THEN 1 ELSE 0 END
    ) AS ceps_invalidos,

    ROUND(
        100.0 * SUM(
            CASE WHEN status_qualidade = 'APTO'
            THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS percentual_aptas,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN status_qualidade = 'APTO'
                 AND status_enriquecimento = 'ENDERECO_ENCONTRADO'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS percentual_aptas_com_endereco,

    CURRENT_TIMESTAMP() AS calculado_em

FROM workspace.gs.vw_ocorrencias_enriquecidas;


-- 2. Indicadores de acessibilidade por bairro.
-- Grupos por cidade/UF/bairro; bloqueios contabilizados como 0 ou 1.

CREATE OR REPLACE TABLE workspace.gs.ouro_ocorrencias_por_bairro
USING DELTA AS
SELECT
    cidade,
    uf,
    bairro,
    COUNT(DISTINCT id) AS total_ocorrencias,

    SUM(
        CASE
            WHEN bloqueio_total_boolean = TRUE
            THEN 1
            ELSE 0
        END
    ) AS bloqueios_totais,

    COUNT(DISTINCT tipo) AS tipos_distintos,

    CURRENT_TIMESTAMP() AS calculado_em

FROM workspace.gs.vw_ocorrencias_enriquecidas

WHERE status_qualidade = 'APTO'
  AND status_enriquecimento = 'ENDERECO_ENCONTRADO'

GROUP BY
    cidade,
    uf,
    bairro;


-- 3. Indicadores de acessibilidade por tipo de barreira.
-- Bairros afetados = numero de bairros distintos para cada tipo.

CREATE OR REPLACE TABLE workspace.gs.ouro_ocorrencias_por_tipo
USING DELTA AS
SELECT
    tipo,

    COUNT(DISTINCT id) AS total_ocorrencias,

    SUM(
        CASE
            WHEN bloqueio_total_boolean = TRUE
            THEN 1
            ELSE 0
        END
    ) AS bloqueios_totais,

    COUNT(DISTINCT bairro) AS bairros_afetados,

    CURRENT_TIMESTAMP() AS calculado_em

FROM workspace.gs.vw_ocorrencias_enriquecidas

WHERE status_qualidade = 'APTO'
  AND status_enriquecimento = 'ENDERECO_ENCONTRADO'

GROUP BY tipo;
