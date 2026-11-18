"""GS 2026.2 — PassoLivre: coleta de ocorrencias ficticias e ViaCEP.

O arquivo CSV e ficticio. As execucoes de catchup repetem um snapshot da
amostra e nao constituem um historico real de denuncias ou de alteracoes de CEP.
"""

import csv
import json
import logging
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.request import Request, urlopen

import pendulum
from airflow.sdk import DAG
from airflow.providers.standard.operators.python import PythonOperator

AMOSTRA = Path("/opt/airflow/amostras/ocorrencias_rpa.csv")
CHEGADA = Path("/opt/airflow/chegada")
COLUNAS = {"id", "cep", "referencia", "tipo", "descricao", "bloqueio_total"}


def salvar_atomicamente(destino: Path, conteudo: str) -> None:
    destino.parent.mkdir(parents=True, exist_ok=True)
    temporario = destino.with_name(destino.name + ".tmp")
    temporario.write_text(conteudo, encoding="utf-8")
    temporario.replace(destino)


def ler_ocorrencias() -> list[dict]:
    if not AMOSTRA.is_file():
        raise FileNotFoundError(f"Arquivo de origem nao encontrado: {AMOSTRA}")
    with AMOSTRA.open("r", encoding="utf-8-sig", newline="") as arquivo:
        leitor = csv.DictReader(arquivo, delimiter=";")
        if not leitor.fieldnames or not COLUNAS.issubset(leitor.fieldnames):
            raise ValueError(f"Cabecalho CSV inesperado: {leitor.fieldnames}")
        registros = list(leitor)
    if not registros:
        raise ValueError("O CSV de ocorrencias esta vazio")
    return registros


def coletar_ocorrencias(ds: str, **_contexto) -> None:
    registros = ler_ocorrencias()
    destino = CHEGADA / "ocorrencias" / f"ocorrencias_{ds}.csv"
    # Copia fiel da amostra, sem filtrar ou corrigir linhas na coleta.
    texto_original = AMOSTRA.read_text(encoding="utf-8-sig")
    salvar_atomicamente(destino, texto_original)
    logging.info("Ocorrencias: %s linhas copiadas para %s", len(registros), destino)


def coletar_viacep(ds: str, **_contexto) -> None:
    registros = ler_ocorrencias()
    # CEP invalido continua no CSV; nao fazemos requisicoes invalidas a API.
    ceps = sorted({
        (linha.get("cep") or "").strip()
        for linha in registros
        if (linha.get("cep") or "").strip().isdigit()
        and len((linha.get("cep") or "").strip()) == 8
    })
    if not ceps:
        raise ValueError("Nao ha CEPs em formato valido para consultar")
    if len(ceps) > 25:
        raise ValueError("A amostra ultrapassou o limite educacional de 25 CEPs por coleta")

    itens = []
    for cep in ceps:
        url = f"https://viacep.com.br/ws/{cep}/json/"
        requisicao = Request(url, headers={"User-Agent": "PassoLivre-GS-2026.2/1.0"})
        with urlopen(requisicao, timeout=25) as resposta:
            dados = json.load(resposta)
        if not isinstance(dados, dict):
            raise ValueError(f"Resposta inesperada da API para CEP {cep}")
        itens.append({
            "cep_consultado": cep,
            "data_logica": ds,
            "consultado_em_utc": datetime.now(timezone.utc).isoformat(),
            "resposta_viacep": dados,
        })
        time.sleep(0.35)  # Pequeno intervalo entre as consultas publicas.

    destino = CHEGADA / "viacep" / f"viacep_{ds}.json"
    # JSON Lines: uma resposta de consulta por linha, facil de ingerir no Spark.
    conteudo = "\n".join(json.dumps(item, ensure_ascii=False) for item in itens) + "\n"
    salvar_atomicamente(destino, conteudo)
    logging.info("ViaCEP: %s consultas salvas em %s", len(itens), destino)


def conferir_chegada(ds: str, **_contexto) -> None:
    arquivo_csv = CHEGADA / "ocorrencias" / f"ocorrencias_{ds}.csv"
    arquivo_json = CHEGADA / "viacep" / f"viacep_{ds}.json"
    for caminho in (arquivo_csv, arquivo_json):
        if not caminho.is_file() or caminho.stat().st_size == 0:
            raise FileNotFoundError(f"Arquivo ausente ou vazio: {caminho}")
    with arquivo_csv.open("r", encoding="utf-8", newline="") as arquivo:
        linhas = list(csv.DictReader(arquivo, delimiter=";"))
    with arquivo_json.open("r", encoding="utf-8") as arquivo:
        respostas = [json.loads(linha) for linha in arquivo if linha.strip()]
    if not linhas or not respostas:
        raise ValueError("Um dos arquivos nao possui registros de dados")
    logging.info("Conferencia OK: %s ocorrencias e %s respostas ViaCEP", len(linhas), len(respostas))


def registrar_falha(contexto: dict) -> None:
    tarefa = contexto.get("task_instance")
    logging.error("Falha na tarefa %s, execucao %s", getattr(tarefa, "task_id", "?"), contexto.get("ds"))


with DAG(
    dag_id="passolivre_coleta",
    description="Coleta agendada da amostra PassoLivre e de enderecos ViaCEP",
    start_date=pendulum.datetime(2026, 11, 14, tz="America/Sao_Paulo"),
    schedule="@daily",
    catchup=True,
    max_active_runs=1,
    default_args={
        "retries": 2,
        "retry_delay": timedelta(minutes=1),
        "on_failure_callback": registrar_falha,
    },
    tags=["passolivre", "gs2026", "dados"],
) as dag:
    tarefa_ocorrencias = PythonOperator(
        task_id="coletar_ocorrencias",
        python_callable=coletar_ocorrencias,
    )
    tarefa_viacep = PythonOperator(
        task_id="coletar_viacep",
        python_callable=coletar_viacep,
    )
    tarefa_conferir = PythonOperator(
        task_id="conferir_chegada",
        python_callable=conferir_chegada,
    )

    [tarefa_ocorrencias, tarefa_viacep] >> tarefa_conferir
