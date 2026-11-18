-- PASSOLIVRE | 02 - CAMADA PRATA
-- Objetivo: normalizar, deduplicar, validar e enriquecer as ocorrencias.
-- Dependencia: 01_bronze.sql carregado em workspace.gs.
-- Ordem: criar tabelas -> view de qualidade -> MERGEs -> view enriquecida.
-- O MERGE das ocorrencias exige id preenchido; linhas sem id nao sao inseridas
-- na Prata e, portanto, nao integram os indicadores da Ouro.

-- 1. Tabela de ocorrencias tratadas (com regras de qualidade).

CREATE TABLE IF NOT EXISTS workspace.gs.prata_ocorrencias (
    id STRING,
    cep STRING,
    referencia STRING,
    tipo STRING,
    descricao STRING,
    bloqueio_total STRING,
    bloqueio_total_boolean BOOLEAN,
    arquivo_origem STRING,
    regra_id_valido INT,
    regra_cep_valido INT,
    regra_descricao_valida INT,
    status_qualidade STRING,
    atualizado_em TIMESTAMP
)
USING DELTA;


-- 2. Tabela de respostas ViaCEP extraidas e classificadas.

CREATE TABLE IF NOT EXISTS workspace.gs.prata_viacep (
    cep_consultado STRING,
    cep_retorno STRING,
    logradouro STRING,
    bairro STRING,
    cidade STRING,
    uf STRING,
    status_consulta STRING,
    erro_api BOOLEAN,
    data_logica DATE,
    consultado_em_utc TIMESTAMP,
    resposta_viacep_json STRING,
    arquivo_origem STRING,
    atualizado_em TIMESTAMP
)
USING DELTA;


-- 3. Normalizacao, deduplicacao e validacao das ocorrencias.
-- CEP fica somente com digitos; duplicatas com mesmo id sao reduzidas a uma.
-- Status APTO exige id, CEP com 8 digitos e descricao preenchida.

CREATE OR REPLACE VIEW workspace.gs.vw_prata_ocorrencias_qualidade AS
WITH normalizados AS (
    SELECT
        NULLIF(TRIM(id), '') AS id,
        REGEXP_REPLACE(COALESCE(TRIM(cep), ''), '[^0-9]', '') AS cep,
        NULLIF(TRIM(referencia), '') AS referencia,
        NULLIF(TRIM(tipo), '') AS tipo,
        NULLIF(TRIM(descricao), '') AS descricao,
        NULLIF(TRIM(bloqueio_total), '') AS bloqueio_total,
        arquivo_origem,
        carregado_em
    FROM workspace.gs.bronze_ocorrencias
),
deduplicados AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY
                arquivo_origem DESC,
                carregado_em DESC,
                COALESCE(descricao, '') DESC,
                COALESCE(cep, '') DESC,
                COALESCE(tipo, '') DESC,
                COALESCE(referencia, '') DESC
        ) AS ordem
    FROM normalizados
)
SELECT
    id,
    cep,
    referencia,
    tipo,
    descricao,
    bloqueio_total,
    arquivo_origem,
    CASE
        WHEN id IS NOT NULL THEN 1
        ELSE 0
    END AS regra_id_valido,
    CASE
        WHEN cep RLIKE '^[0-9]{8}$' THEN 1
        ELSE 0
    END AS regra_cep_valido,
    CASE
        WHEN descricao IS NOT NULL THEN 1
        ELSE 0
    END AS regra_descricao_valida,
    CASE
        WHEN id IS NOT NULL
             AND cep RLIKE '^[0-9]{8}$'
             AND descricao IS NOT NULL
        THEN 'APTO'
        ELSE 'PENDENTE'
    END AS status_qualidade
FROM deduplicados
WHERE ordem = 1;


-- 4. Atualizacao incremental das ocorrencias por id.
-- O operador <=> compara valores com seguranca em relacao a NULL.
-- Valores reconhecidos como bloqueio total: sim/s/true/1 (e negativos
-- correspondentes); respostas desconhecidas permanecem NULL.

MERGE INTO workspace.gs.prata_ocorrencias AS destino
USING (
    SELECT
        id,
        cep,
        referencia,
        tipo,
        descricao,
        bloqueio_total,
        CASE
            WHEN LOWER(TRIM(bloqueio_total))
                IN ('sim', 's', 'true', '1')
            THEN TRUE
            WHEN LOWER(TRIM(bloqueio_total))
                IN ('nao', 'não', 'n', 'false', '0')
            THEN FALSE
            ELSE NULL
        END AS bloqueio_total_boolean,
        arquivo_origem,
        regra_id_valido,
        regra_cep_valido,
        regra_descricao_valida,
        status_qualidade
    FROM workspace.gs.vw_prata_ocorrencias_qualidade
    WHERE id IS NOT NULL
) AS origem
ON destino.id = origem.id

WHEN MATCHED AND (
    NOT (destino.cep <=> origem.cep)
    OR NOT (destino.referencia <=> origem.referencia)
    OR NOT (destino.tipo <=> origem.tipo)
    OR NOT (destino.descricao <=> origem.descricao)
    OR NOT (destino.bloqueio_total <=> origem.bloqueio_total)
    OR NOT (destino.bloqueio_total_boolean <=> origem.bloqueio_total_boolean)
    OR NOT (destino.arquivo_origem <=> origem.arquivo_origem)
    OR NOT (destino.regra_id_valido <=> origem.regra_id_valido)
    OR NOT (destino.regra_cep_valido <=> origem.regra_cep_valido)
    OR NOT (destino.regra_descricao_valida <=> origem.regra_descricao_valida)
    OR NOT (destino.status_qualidade <=> origem.status_qualidade)
)
THEN UPDATE SET
    destino.cep = origem.cep,
    destino.referencia = origem.referencia,
    destino.tipo = origem.tipo,
    destino.descricao = origem.descricao,
    destino.bloqueio_total = origem.bloqueio_total,
    destino.bloqueio_total_boolean = origem.bloqueio_total_boolean,
    destino.arquivo_origem = origem.arquivo_origem,
    destino.regra_id_valido = origem.regra_id_valido,
    destino.regra_cep_valido = origem.regra_cep_valido,
    destino.regra_descricao_valida = origem.regra_descricao_valida,
    destino.status_qualidade = origem.status_qualidade,
    destino.atualizado_em = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (
    id,
    cep,
    referencia,
    tipo,
    descricao,
    bloqueio_total,
    bloqueio_total_boolean,
    arquivo_origem,
    regra_id_valido,
    regra_cep_valido,
    regra_descricao_valida,
    status_qualidade,
    atualizado_em
)
VALUES (
    origem.id,
    origem.cep,
    origem.referencia,
    origem.tipo,
    origem.descricao,
    origem.bloqueio_total,
    origem.bloqueio_total_boolean,
    origem.arquivo_origem,
    origem.regra_id_valido,
    origem.regra_cep_valido,
    origem.regra_descricao_valida,
    origem.status_qualidade,
    CURRENT_TIMESTAMP()
);


-- 5. Tratamento e atualizacao dos dados ViaCEP.
-- A resposta mais recente por CEP e extraida do JSON e recebe status
-- VALIDO, ERRO_API ou SEM_ENDERECO; MERGE evita atualizar linhas iguais.

MERGE INTO workspace.gs.prata_viacep AS destino
USING (
    WITH respostas AS (
        SELECT
            cep_consultado,
            NULLIF(TRIM(GET_JSON_OBJECT(resposta_viacep_json, '$.cep')), '') AS cep_retorno,
            NULLIF(TRIM(GET_JSON_OBJECT(resposta_viacep_json, '$.logradouro')), '') AS logradouro,
            NULLIF(TRIM(GET_JSON_OBJECT(resposta_viacep_json, '$.bairro')), '') AS bairro,
            NULLIF(TRIM(GET_JSON_OBJECT(resposta_viacep_json, '$.localidade')), '') AS cidade,
            NULLIF(TRIM(GET_JSON_OBJECT(resposta_viacep_json, '$.uf')), '') AS uf,
            COALESCE(
                TRY_CAST(GET_JSON_OBJECT(resposta_viacep_json, '$.erro') AS BOOLEAN),
                FALSE
            ) AS erro_api,
            TRY_CAST(data_logica AS DATE) AS data_logica,
            TRY_CAST(consultado_em_utc AS TIMESTAMP) AS consultado_em_utc,
            resposta_viacep_json,
            arquivo_origem,
            ROW_NUMBER() OVER (
                PARTITION BY cep_consultado
                ORDER BY data_logica DESC,
                         consultado_em_utc DESC,
                         arquivo_origem DESC
            ) AS ordem
        FROM workspace.gs.bronze_viacep
    )
    SELECT
        cep_consultado,
        cep_retorno,
        logradouro,
        bairro,
        cidade,
        uf,
        CASE
            WHEN erro_api THEN 'ERRO_API'
            WHEN cep_retorno IS NULL THEN 'SEM_ENDERECO'
            ELSE 'VALIDO'
        END AS status_consulta,
        erro_api,
        data_logica,
        consultado_em_utc,
        resposta_viacep_json,
        arquivo_origem
    FROM respostas
    WHERE ordem = 1
) AS origem

ON destino.cep_consultado = origem.cep_consultado


WHEN MATCHED AND NOT (
    destino.cep_retorno <=> origem.cep_retorno
    AND destino.logradouro <=> origem.logradouro
    AND destino.bairro <=> origem.bairro
    AND destino.cidade <=> origem.cidade
    AND destino.uf <=> origem.uf
    AND destino.status_consulta <=> origem.status_consulta
    AND destino.erro_api <=> origem.erro_api
    AND destino.data_logica <=> origem.data_logica
    AND destino.consultado_em_utc <=> origem.consultado_em_utc
    AND destino.resposta_viacep_json <=> origem.resposta_viacep_json
    AND destino.arquivo_origem <=> origem.arquivo_origem
)
THEN UPDATE SET
    destino.cep_retorno = origem.cep_retorno,
    destino.logradouro = origem.logradouro,
    destino.bairro = origem.bairro,
    destino.cidade = origem.cidade,
    destino.uf = origem.uf,
    destino.status_consulta = origem.status_consulta,
    destino.erro_api = origem.erro_api,
    destino.data_logica = origem.data_logica,
    destino.consultado_em_utc = origem.consultado_em_utc,
    destino.resposta_viacep_json = origem.resposta_viacep_json,
    destino.arquivo_origem = origem.arquivo_origem,
    destino.atualizado_em = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (
    cep_consultado,
    cep_retorno,
    logradouro,
    bairro,
    cidade,
    uf,
    status_consulta,
    erro_api,
    data_logica,
    consultado_em_utc,
    resposta_viacep_json,
    arquivo_origem,
    atualizado_em
)
VALUES (
    origem.cep_consultado,
    origem.cep_retorno,
    origem.logradouro,
    origem.bairro,
    origem.cidade,
    origem.uf,
    origem.status_consulta,
    origem.erro_api,
    origem.data_logica,
    origem.consultado_em_utc,
    origem.resposta_viacep_json,
    origem.arquivo_origem,
    CURRENT_TIMESTAMP()
);


-- 6. Integracao das ocorrencias com os enderecos ViaCEP
-- LEFT JOIN preserva ocorrencias com CEP sem consulta ou com erro.
-- Ajuste defensivo: status_consulta NULL nao equivale a endereco encontrado.

CREATE OR REPLACE VIEW workspace.gs.vw_ocorrencias_enriquecidas AS
SELECT
    o.id,
    o.tipo,
    o.cep,
    o.referencia,
    o.descricao,
    o.bloqueio_total_boolean,
    o.status_qualidade,
    v.logradouro,
    v.bairro,
    v.cidade,
    v.uf,
    v.status_consulta,
    CASE
        WHEN o.regra_cep_valido = 0 THEN 'CEP_INVALIDO'
        WHEN v.cep_consultado IS NULL THEN 'SEM_CONSULTA'
        WHEN v.status_consulta IS NULL OR v.status_consulta <> 'VALIDO'
            THEN 'ENDERECO_NAO_ENCONTRADO'
        ELSE 'ENDERECO_ENCONTRADO'
    END AS status_enriquecimento
FROM workspace.gs.prata_ocorrencias AS o
LEFT JOIN workspace.gs.prata_viacep AS v
    ON o.cep = v.cep_consultado;
