-- PASSOLIVRE | 04 - MODELO DIMENSIONAL (STAR SCHEMA)
-- Dependencia: vw_ocorrencias_enriquecidas (02_prata.sql).
-- Granularidade da fato: uma linha por ocorrencia APTO com endereco encontrado.
-- Modelo: dim_tipo_barreira (1:N) fato_ocorrencias (N:1) dim_localizacao.
-- As chaves primarias/estrangeiras sao LOGICAS; validar relacionamentos.
-- IMPORTANTE: ROW_NUMBER gera chaves por ordem; com novos membros, os ids
-- podem mudar. Sempre recriar as duas dimensoes ANTES da tabela fato.
-- Recriacao nao e automatizada pelo Airflow neste projeto.

-- 1. Dimensao dos tipos de barreira.

CREATE OR REPLACE TABLE workspace.gs.dim_tipo_barreira
USING DELTA AS
SELECT
    ROW_NUMBER() OVER (ORDER BY tipo) AS id_tipo,
    tipo AS tipo_barreira
FROM (
    SELECT DISTINCT
        tipo
    FROM workspace.gs.vw_ocorrencias_enriquecidas
    WHERE status_qualidade = 'APTO'
      AND status_enriquecimento = 'ENDERECO_ENCONTRADO'
      AND tipo IS NOT NULL
);


-- 2. Dimensao de localizacao.
-- Combinacao unica de UF, cidade e bairro para o conjunto elegivel.

CREATE OR REPLACE TABLE workspace.gs.dim_localizacao
USING DELTA AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY uf, cidade, bairro
    ) AS id_localizacao,
    cidade,
    uf,
    bairro
FROM (
    SELECT DISTINCT
        cidade,
        uf,
        bairro
    FROM workspace.gs.vw_ocorrencias_enriquecidas
    WHERE status_qualidade = 'APTO'
      AND status_enriquecimento = 'ENDERECO_ENCONTRADO'
      AND cidade IS NOT NULL
      AND uf IS NOT NULL
      AND bairro IS NOT NULL
);


-- 3. Tabela fato de ocorrencias de acessibilidade.
-- id_tipo e id_localizacao fazem a ligacao logica com as dimensoes.
-- quantidade_ocorrencias = 1 por linha; bloqueio total = 1 ou 0.

CREATE OR REPLACE TABLE workspace.gs.fato_ocorrencias
USING DELTA AS
SELECT
    o.id AS id_ocorrencia,
    t.id_tipo,
    l.id_localizacao,
    o.cep,
    o.referencia,
    o.descricao,
    o.bloqueio_total_boolean,

    1 AS quantidade_ocorrencias,

    CASE
        WHEN o.bloqueio_total_boolean = TRUE
        THEN 1
        ELSE 0
    END AS quantidade_bloqueios_totais,

    CURRENT_TIMESTAMP() AS calculado_em

FROM workspace.gs.vw_ocorrencias_enriquecidas AS o

INNER JOIN workspace.gs.dim_tipo_barreira AS t
    ON o.tipo = t.tipo_barreira

INNER JOIN workspace.gs.dim_localizacao AS l
    ON o.cidade = l.cidade
    AND o.uf = l.uf
    AND o.bairro = l.bairro

WHERE o.status_qualidade = 'APTO'
  AND o.status_enriquecimento = 'ENDERECO_ENCONTRADO';
