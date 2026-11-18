# Privacidade e Proteção de Dados — PassoLivre

## 1. Objetivo

Este documento descreve as práticas de tratamento de dados, os riscos de privacidade e as medidas de proteção previstas para o projeto acadêmico PassoLivre.

O projeto busca identificar e analisar barreiras de acessibilidade urbana utilizando um pipeline de dados com Apache Airflow, ViaCEP e Databricks.

## 2. Dados utilizados

O conjunto de ocorrências contém os seguintes campos:

| Campo | Finalidade |
|---|---|
| `id` | Identificação da ocorrência |
| `cep` | Referência geográfica |
| `referencia` | Descrição complementar da localização |
| `tipo` | Classificação da barreira |
| `descricao` | Descrição do problema |
| `bloqueio_total` | Indicação de impedimento total da passagem |

A integração com o ViaCEP acrescenta informações de logradouro, bairro, cidade e unidade federativa.

O conjunto de ocorrências utilizado na demonstração é **fictício**, não sendo composto por denúncias reais de cidadãos.

## 3. Minimização de dados

A estrutura atual não exige nome, CPF, telefone, e-mail ou outros identificadores pessoais diretos para realizar as análises.

Entretanto, dados de localização e campos descritivos podem conter informações pessoais ou permitir identificação indireta, dependendo de seu conteúdo e de sua combinação com outras informações.

Em uma aplicação real, deverão ser adotadas medidas como:

- Não solicitar dados pessoais desnecessários.
- Evitar informações identificáveis nas descrições de ocorrências.
- Validar e tratar textos livres antes do armazenamento ou da publicação.
- Limitar a granularidade das informações apresentadas publicamente, quando necessário.

## 4. Finalidade e tratamento

O tratamento previsto tem como finalidade organizar registros de barreiras de acessibilidade, verificar sua qualidade, enriquecer informações geográficas e gerar indicadores para apoiar análises urbanas.

O fluxo do projeto é:

1. Coleta de ocorrências e respostas do ViaCEP.
2. Armazenamento inicial na camada Bronze.
3. Normalização, validação e deduplicação na camada Prata.
4. Geração de indicadores e modelo dimensional na camada Ouro.
5. Apresentação de resultados no dashboard.

A consulta ao ViaCEP envolve o envio dos CEPs necessários ao serviço externo. Em uma implantação real, esse compartilhamento e suas condições deverão ser considerados na avaliação de privacidade.

## 5. Segurança e controle de acesso

O projeto utiliza arquivos locais e recursos do Databricks para processamento e armazenamento.

Para uma implantação real, são recomendados:

- Controle de acesso por usuário e função.
- Proteção de credenciais e segredos fora do código-fonte.
- Restrição de acesso aos arquivos brutos e registros detalhados.
- Registro de operações relevantes para auditoria.
- Utilização de conexões seguras.
- Políticas de retenção e exclusão de informações.
- Revisão dos dados antes de sua publicação em repositórios ou dashboards.

Essas medidas representam recomendações de proteção e não devem ser interpretadas como funcionalidades já integralmente implementadas ou auditadas.

## 6. Qualidade e rastreabilidade

O pipeline implementa normalização, validação e deduplicação de ocorrências, além de registrar informações de origem e processamento.

Registros podem ser classificados como `APTO` ou `PENDENTE`, permitindo distinguir informações que atendem às regras de qualidade definidas.

Esses controles contribuem para a confiabilidade das análises, mas não substituem controles específicos de proteção de dados pessoais.

## 7. Retenção e direitos dos titulares

Como a demonstração utiliza ocorrências fictícias, não foi implementado um procedimento operacional completo de atendimento a titulares de dados pessoais.

Antes da utilização com dados reais, deverão ser definidos:

- Responsáveis pelo tratamento e pela proteção dos dados.
- Base legal apropriada para cada finalidade.
- Aviso de privacidade e canais de atendimento.
- Procedimentos para exercício dos direitos dos titulares.
- Prazos de conservação e critérios de exclusão.
- Procedimentos de resposta a incidentes de segurança.

## 8. Limitações e conformidade

O PassoLivre é um protótipo acadêmico. O uso de dados fictícios reduz os riscos de privacidade nesta demonstração, mas não garante automaticamente conformidade em uma futura implantação.

A adequação à Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018) dependerá das características reais da operação, dos dados coletados, das finalidades, da base legal aplicável e das medidas técnicas e administrativas efetivamente adotadas.

## 9. Referências

- Lei Geral de Proteção de Dados Pessoais — Lei nº 13.709/2018.
- Autoridade Nacional de Proteção de Dados (ANPD) — orientações e materiais educativos.
- Princípios da finalidade, adequação, necessidade, transparência, segurança, prevenção e responsabilização.