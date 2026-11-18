
# Consultas Analíticas — PassoLivre

## Objetivo

As consultas analíticas do PassoLivre utilizam o modelo
dimensional da camada Ouro para identificar padrões
de barreiras de acessibilidade e apoiar a priorização
de intervenções urbanas.

Os dados são fictícios e utilizados exclusivamente
para demonstração acadêmica.

As consultas SQL estão disponíveis em:
`databricks/05_consultas_analiticas.sql`

## Consulta 1 — Ocorrências por bairro

**Pergunta:** Quais bairros concentram mais ocorrências?

| Bairro | Ocorrências | Bloqueios totais |
|---|---:|---:|
| Bela Vista | 4 | 2 |
| Pinheiros | 2 | 1 |
| Paraíso | 2 | 0 |
| Sé | 2 | 0 |

**Interpretação:** Bela Vista concentra 40% das
ocorrências analisadas e dois dos três bloqueios
totais. Na amostra, é uma possível prioridade
para análise e intervenção.

## Consulta 2 — Tipos de barreira

**Pergunta:** Quais tipos de barreira apresentam
maior frequência e proporção de bloqueios?

| Tipo | Ocorrências | Bloqueios | Percentual |
|---|---:|---:|---:|
| obstaculo | 2 | 2 | 100,00% |
| desnivel | 3 | 1 | 33,33% |
| buraco | 3 | 0 | 0,00% |
| piso_tatil_danificado | 2 | 0 | 0,00% |

**Interpretação:** Buracos e desníveis são os
tipos mais frequentes. Entretanto, obstáculos
apresentam a maior proporção de bloqueios
totais na amostra.

## Consulta 3 — Tipos de barreira por bairro

**Pergunta:** Como os tipos de barreira
estão distribuídos entre os bairros?

A consulta cruza a dimensão de localização
com a dimensão de tipos de barreira.

**Resultados principais:**

- Bela Vista: 2 obstáculos, 1 desnível
  e 1 piso tátil danificado.
- Paraíso: 1 buraco e 1 piso tátil danificado.
- Pinheiros: 1 desnível e 1 buraco.
- Sé: 1 buraco e 1 desnível.

**Interpretação:** Os bloqueios totais da
Bela Vista são causados por obstáculos.
Em Pinheiros, o bloqueio total é causado
por um desnível. Isso permite identificar
necessidades específicas por bairro.

## Consulta 4 — Percentual de bloqueios por bairro

**Pergunta:** Quais bairros possuem maior
proporção de ocorrências com bloqueio total?

| Bairro | Ocorrências | Bloqueios | Percentual |
|---|---:|---:|---:|
| Bela Vista | 4 | 2 | 50,00% |
| Pinheiros | 2 | 1 | 50,00% |
| Paraíso | 2 | 0 | 0,00% |
| Sé | 2 | 0 | 0,00% |

**Interpretação:** Bela Vista e Pinheiros
apresentam a mesma proporção de bloqueios.
Entretanto, Bela Vista apresenta maior
quantidade absoluta de ocorrências e bloqueios.

## Consulta 5 — Indicador de impacto potencial

**Pergunta:** Qual é a cobertura dos dados
processados e quantos bloqueios foram identificados?

| Indicador | Resultado |
|---|---:|
| Total de ocorrências únicas | 14 |
| Ocorrências aptas | 11 |
| Aptas com endereço | 10 |
| Percentual de aptas | 78,57% |
| Percentual de aptas com endereço | 71,43% |
| Bloqueios totais identificados | 3 |
| Bloqueios entre ocorrências mapeadas | 30,00% |

**Interpretação:** O pipeline transformou
10 das 14 ocorrências únicas em registros
aptos com localização identificada.

Entre essas 10 ocorrências, três representam
bloqueios totais, possibilitando sua
identificação e priorização pelo MVP.

O indicador demonstra capacidade técnica
de processamento e identificação, mas não
comprova impacto social real.

## Conclusão

As cinco consultas demonstram como o modelo
dimensional permite analisar:

1. Distribuição territorial das ocorrências.
2. Frequência e criticidade dos tipos de barreira.
3. Relação entre localização e tipo de problema.
4. Proporção de bloqueios por bairro.
5. Cobertura dos dados e impacto potencial.

Esses resultados podem apoiar o planejamento
de intervenções e a apresentação de indicadores
no MVP PassoLivre.

## Limitações

A base de dados é fictícia e possui apenas
14 ocorrências únicas, das quais 10 integram
o modelo dimensional.

Os resultados não devem ser generalizados
para os bairros reais de São Paulo.

Não foram medidas intervenções realizadas,
redução de acidentes ou melhorias efetivas
na mobilidade urbana.
