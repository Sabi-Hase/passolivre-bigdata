-- PASSOLIVRE | 01 - CAMADA BRONZE
-- Objetivo: guardar dados brutos de ocorrencias e respostas do ViaCEP.
-- Fonte: arquivos CSV/JSON em /Volumes/workspace/gs/chegada/.
-- Executar antes de 02_prata.sql, com acesso ao catalogo workspace.gs.
-- COPY INTO com force=false evita recarregar arquivos ja processados pelo comando.
-- Dados ficticios para demonstracao academica.

-- 1. Estrutura das ocorrencias recebidas (sem tratamento de qualidade).

CREATE TABLE IF NOT EXISTS workspace.gs.bronze_ocorrencias (
    id STRING,
    cep STRING,
    referencia STRING,
    tipo STRING,
    descricao STRING,
    bloqueio_total STRING,
    arquivo_origem STRING,
    carregado_em TIMESTAMP
)
USING DELTA;


-- 2. Estrutura das respostas ViaCEP (JSON preservado como texto).

CREATE TABLE IF NOT EXISTS workspace.gs.bronze_viacep (
    cep_consultado STRING,
    data_logica STRING,
    consultado_em_utc STRING,
    resposta_viacep_json STRING,
    arquivo_origem STRING,
    carregado_em TIMESTAMP
)
USING DELTA;


-- 3. Carga incremental dos CSVs de ocorrencias.
-- Manter o delimitador ";" e a leitura de colunas como STRING.

COPY INTO workspace.gs.bronze_ocorrencias
FROM (
    SELECT
        id,
        cep,
        referencia,
        tipo,
        descricao,
        bloqueio_total,
        _metadata.file_path AS arquivo_origem,
        current_timestamp() AS carregado_em
    FROM '/Volumes/workspace/gs/chegada/ocorrencias/'
)
FILEFORMAT = CSV
FORMAT_OPTIONS (
    'header' = 'true',
    'delimiter' = ';',
    'inferSchema' = 'false'
)
COPY_OPTIONS (
    'force' = 'false'
);


-- 4. Carga incremental dos JSONs do ViaCEP.
-- Salva resposta_viacep como JSON para transformacao posterior.

COPY INTO workspace.gs.bronze_viacep
FROM (
    SELECT
        cep_consultado,
        data_logica,
        consultado_em_utc,
        to_json(resposta_viacep) AS resposta_viacep_json,
        _metadata.file_path AS arquivo_origem,
        current_timestamp() AS carregado_em
    FROM '/Volumes/workspace/gs/chegada/viacep/'
)
FILEFORMAT = JSON
FORMAT_OPTIONS (
    'multiLine' = 'false'
)
COPY_OPTIONS (
    'force' = 'false'
);
