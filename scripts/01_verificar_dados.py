"""Primeira verificação local de uma amostra fictícia do RPA PassoLivre.

Sem bibliotecas externas e sem contato com serviços na internet.
"""
import csv
from collections import Counter
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
ARQUIVO = RAIZ / "amostras" / "ocorrencias_rpa.csv"
COLUNAS = {"id", "cep", "referencia", "tipo", "descricao", "bloqueio_total"}


def main() -> None:
    if not ARQUIVO.is_file():
        raise SystemExit(f"ERRO: arquivo não encontrado: {ARQUIVO}")

    with ARQUIVO.open("r", encoding="utf-8-sig", newline="") as f:
        leitor = csv.DictReader(f, delimiter=";")
        if not leitor.fieldnames or set(leitor.fieldnames) != COLUNAS:
            raise SystemExit(f"ERRO: cabeçalho inesperado: {leitor.fieldnames}")
        linhas = list(leitor)

    contagem_ids = Counter(row["id"].strip() for row in linhas)
    duplicatas = sum(qtd - 1 for qtd in contagem_ids.values() if qtd > 1)
    ceps_vazios = sum(not row["cep"].strip() for row in linhas)
    ceps_formato_invalido = sum(
        bool(row["cep"].strip()) and not row["cep"].strip().replace("-", "").isdigit()
        or bool(row["cep"].strip()) and len(row["cep"].strip().replace("-", "")) != 8
        for row in linhas
    )
    descricoes_vazias = sum(not row["descricao"].strip() for row in linhas)

    print("=== PassoLivre | Etapa 1: verificacao da amostra ===")
    print(f"Arquivo: {ARQUIVO}")
    print(f"Registros totais: {len(linhas)}")
    print(f"IDs distintos: {len(contagem_ids)}")
    print(f"Registros com ID repetido: {duplicatas}")
    print(f"CEP vazio: {ceps_vazios}")
    print(f"CEP com formato invalido: {ceps_formato_invalido}")
    print(f"Descricao vazia: {descricoes_vazias}")
    print("IMPORTANTE: dados de ocorrencias ficticios; CEPs nao comprovam barreiras reais.")
    esperado = (15, 14, 1, 1, 1, 1)
    encontrado = (len(linhas), len(contagem_ids), duplicatas, ceps_vazios,
                  ceps_formato_invalido, descricoes_vazias)
    if encontrado != esperado:
        raise SystemExit(f"ERRO: dados diferentes da amostra inicial: {encontrado}")
    print("SUCESSO: arquivo lido e estrutura validada.")


if __name__ == "__main__":
    main()
