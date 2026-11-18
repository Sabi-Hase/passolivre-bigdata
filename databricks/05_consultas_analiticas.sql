-- PASSOLIVRE | 05 - CONSULTAS ANALITICAS
-- Fonte: modelo dimensional (04_modelo_dimensional.sql) e resumo Ouro.
-- Cada SELECT responde a uma pergunta do MVP e pode ser executado isolado.
-- Resultados abaixo referem-se a AMOSTRA FICTICIA validada no Databricks.
-- Nao extrapolar conclusoes para a populacao real de Sao Paulo.

-- CONSULTA 1. Quais bairros concentram mais ocorrencias e bloqueios?
-- Resultado: Bela Vista 4/2; Pinheiros 2/1; Paraiso 2/0; Se 2/0
-- (numeros no formato ocorrencias/bloqueios).
-- Interpretacao: Bela Vista concentra 40% das ocorrencias da amostra.

SELECT
    l.bairro,
    l.cidade,
    l.uf,
    SUM(f.quantidade_ocorrencias) AS total_ocorrencias,
    SUM(f.quantidade_bloqueios_totais) AS bloqueios_totais
FROM workspace.gs.fato_ocorrencias AS f
INNER JOIN workspace.gs.dim_localizacao AS l
    ON f.id_localizacao = l.id_localizacao
GROUP BY
    l.bairro,
    l.cidade,
    l.uf
ORDER BY
    total_ocorrencias DESC,
    bloqueios_totais DESC,
    l.bairro;


-- CONSULTA 2. Quais tipos sao mais frequentes e quais bloqueiam mais?
-- Resultado: obstaculo 2/2 (100%); desnivel 3/1 (33,33%);
-- buraco 3/0; piso_tatil_danificado 2/0.
-- Interpretacao: na amostra, todos os obstaculos causaram bloqueio total.

SELECT
    t.tipo_barreira,
    SUM(f.quantidade_ocorrencias) AS total_ocorrencias,
    SUM(f.quantidade_bloqueios_totais) AS bloqueios_totais,
    ROUND(
        100.0 * SUM(f.quantidade_bloqueios_totais)
        / SUM(f.quantidade_ocorrencias),
        2
    ) AS percentual_bloqueios
FROM workspace.gs.fato_ocorrencias AS f
INNER JOIN workspace.gs.dim_tipo_barreira AS t
    ON f.id_tipo = t.id_tipo
GROUP BY
    t.tipo_barreira
ORDER BY
    bloqueios_totais DESC,
    total_ocorrencias DESC,
    t.tipo_barreira;


-- CONSULTA 3. Que tipos de barreira aparecem em cada bairro?
-- Resultado: 9 combinacoes bairro/tipo em 10 ocorrencias.
-- Interpretacao: os dois bloqueios da Bela Vista sao obstaculos;
-- Pinheiros tem um bloqueio por desnivel.

SELECT
    l.bairro,
    l.cidade,
    l.uf,
    t.tipo_barreira,
    SUM(f.quantidade_ocorrencias) AS total_ocorrencias,
    SUM(f.quantidade_bloqueios_totais) AS bloqueios_totais
FROM workspace.gs.fato_ocorrencias AS f

INNER JOIN workspace.gs.dim_localizacao AS l
    ON f.id_localizacao = l.id_localizacao

INNER JOIN workspace.gs.dim_tipo_barreira AS t
    ON f.id_tipo = t.id_tipo

GROUP BY
    l.bairro,
    l.cidade,
    l.uf,
    t.tipo_barreira

ORDER BY
    l.bairro,
    total_ocorrencias DESC,
    bloqueios_totais DESC,
    t.tipo_barreira;


-- CONSULTA 4. Quais bairros possuem maior percentual de bloqueio total?
-- Resultado: Bela Vista e Pinheiros 50%; Paraiso e Se 0%.
-- Interpretacao: a mesma proporcao nao significa o mesmo numero absoluto.

SELECT
    l.bairro,
    l.cidade,
    l.uf,

    SUM(f.quantidade_ocorrencias) AS total_ocorrencias,

    SUM(f.quantidade_bloqueios_totais) AS bloqueios_totais,

    ROUND(
        100.0 * SUM(f.quantidade_bloqueios_totais)
        / NULLIF(SUM(f.quantidade_ocorrencias), 0),
        2
    ) AS percentual_bloqueios

FROM workspace.gs.fato_ocorrencias AS f

INNER JOIN workspace.gs.dim_localizacao AS l
    ON f.id_localizacao = l.id_localizacao

GROUP BY
    l.bairro,
    l.cidade,
    l.uf

ORDER BY
    percentual_bloqueios DESC,
    bloqueios_totais DESC,
    l.bairro;


-- CONSULTA 5. Qual a cobertura dos dados e o impacto POTENCIAL?
-- Resultado: 14 ocorrencias unicas, 11 aptas, 10 aptas com endereco,
-- 78,57% aptas, 71,43% aptas com endereco e 3 bloqueios (30% das 10).
-- Interpretacao: capacidade de identificar/priorizar barreiras;
-- NAO e evidencia de melhoria efetiva da mobilidade ou reducao de acidentes.

SELECT
    r.total_ocorrencias,
    r.ocorrencias_aptas,
    r.aptas_com_endereco,
    r.percentual_aptas,
    r.percentual_aptas_com_endereco,

    f.bloqueios_totais_identificados,

    ROUND(
        100.0 * f.bloqueios_totais_identificados
        / NULLIF(r.aptas_com_endereco, 0),
        2
    ) AS percentual_bloqueios_criticos

FROM workspace.gs.ouro_resumo_acessibilidade AS r

CROSS JOIN (
    SELECT
        COUNT(*) AS ocorrencias_mapeadas,
        SUM(quantidade_bloqueios_totais)
            AS bloqueios_totais_identificados
    FROM workspace.gs.fato_ocorrencias
) AS f;
