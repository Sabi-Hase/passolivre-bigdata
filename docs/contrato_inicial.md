# PassoLivre — contrato inicial de dados (proposta)

Este contrato é uma proposta para a disciplina de Big Data; ainda não é uma integração implementada com o Applied.

## Fontes

1. **Registros fictícios do RPA:** CSV `id;cep;referencia;tipo;descricao;bloqueio_total`,
   reproduzido em `amostras/ocorrencias_rpa.csv` para a Etapa 1. Não representa denúncias reais.
2. **ViaCEP:** `https://viacep.com.br/ws/{cep}/json/`, para enriquecer CEPs válidos.
   Endereços reais retornados pela API **não comprovam** a existência dos obstáculos.

## Chaves e semântica

- Identificador de ocorrência: `id` (ex.: `PL-001`); deduplicação por ID, não por CEP.
- CEP é texto com 8 dígitos, incluindo zeros à esquerda.
- `bloqueio_total` (`sim`/`nao`) determina prioridade de *triagem*, não um diagnóstico de risco.
- Registro da triagem (apto/pendente/duplicado) não equivale a resolução.
- Para tempo de resolução serão necessários `aberta_em` e `resolvida_em`, ainda não existentes.

## Privacidade e publicação

Não publicar fotos com rostos, localização exata de pessoas, identificadores pessoais,
senhas, tokens ou logs sensíveis. A amostra tem apenas referências fictícias.

## Ingestão futura

Airflow 3 salva arquivos datados em `chegada/<fonte>/` no computador; upload ao Volume no
Databricks Free Edition ocorrerá em **dois lotes** por interface; Bronze (dados brutos),
Prata (MERGE, tipagem, qualidade), Ouro (fato, dimensões, SQL e contrato com MVP).
