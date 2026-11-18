"""Reproduz a amostra fictícia original do PassoLivre (Global Solution 2026.2).

Execução na raiz do repositório:
    python scripts/02_gerar_amostra_ficticia.py

A saída é salva em output/ (pasta ignorada pelo Git). O arquivo de entrada
amostras/ocorrencias_rpa.csv NÃO é alterado e a DAG do Airflow NÃO é executada.
"""

from __future__ import annotations

import csv
import hashlib
import io
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ORIGINAL = RAIZ / "amostras" / "ocorrencias_rpa.csv"
GERADO = RAIZ / "output" / "ocorrencias_rpa_gerada.csv"

CAMPOS = ("id", "cep", "referencia", "tipo", "descricao", "bloqueio_total")
SHA256_ORIGINAL = "b33583798a2e825fb18324ce83a353b196f863e4e3a3fd1389d435d56e426202"

# Mesma ordem, acentuação, CEPs e valores da amostra utilizada na DAG.
# A duplicata de PL-001 e os dados inválidos/incompletos são intencionais:
# permitem demonstrar deduplicação e regras de qualidade na camada Prata.
OCORRENCIAS = (
    ("PL-001", "01001000", "Ponto fictício 01 — referência de teste", "buraco", "Buraco dificulta a passagem na calçada.", "nao"),
    ("PL-002", "01310100", "Ponto fictício 02 — referência de teste", "desnivel", "Desnível na passagem exige avaliação.", "nao"),
    ("PL-003", "01310930", "Ponto fictício 03 — referência de teste", "obstaculo", "Objeto bloqueia a circulação na calçada.", "sim"),
    ("PL-004", "04003000", "Ponto fictício 04 — referência de teste", "piso_tatil_danificado", "Trecho de piso tátil danificado precisa de avaliação.", "nao"),
    ("PL-005", "05407002", "Ponto fictício 05 — referência de teste", "buraco", "Buraco dificulta a passagem na calçada.", "nao"),
    ("PL-006", "01001000", "Ponto fictício 06 — referência de teste", "desnivel", "Desnível na passagem exige avaliação.", "nao"),
    ("PL-007", "01310100", "Ponto fictício 07 — referência de teste", "obstaculo", "Objeto bloqueia a circulação na calçada.", "sim"),
    ("PL-008", "01310930", "Ponto fictício 08 — referência de teste", "piso_tatil_danificado", "Trecho de piso tátil danificado precisa de avaliação.", "nao"),
    ("PL-009", "04003000", "Ponto fictício 09 — referência de teste", "buraco", "Buraco dificulta a passagem na calçada.", "nao"),
    ("PL-010", "05407002", "Ponto fictício 10 — referência de teste", "desnivel", "Desnível na passagem exige avaliação.", "sim"),
    ("PL-001", "01001000", "Ponto fictício 01 — referência de teste", "buraco", "Buraco dificulta a passagem na calçada.", "nao"),
    ("PL-012", "", "Ponto fictício 02 — referência de teste", "desnivel", "Desnível na passagem exige avaliação.", "nao"),
    ("PL-013", "12A45", "Ponto fictício 03 — referência de teste", "obstaculo", "Objeto bloqueia a circulação na calçada.", "sim"),
    ("PL-014", "99999999", "Ponto fictício 04 — referência de teste", "piso_tatil_danificado", "Trecho de piso tátil danificado precisa de avaliação.", "nao"),
    ("PL-015", "05407002", "Ponto fictício 05 — referência de teste", "buraco", "", "nao"),
)


def montar_csv() -> bytes:
    """Gera bytes UTF-8 e finais de linha LF, independentemente do Windows."""
    texto = io.StringIO(newline="")
    escritor = csv.writer(texto, delimiter=";", lineterminator="\n")
    escritor.writerow(CAMPOS)
    escritor.writerows(OCORRENCIAS)
    return texto.getvalue().encode("utf-8")


def main() -> None:
    dados = montar_csv()
    hash_gerado = hashlib.sha256(dados).hexdigest()
    if hash_gerado != SHA256_ORIGINAL:
        raise RuntimeError("A geração não reproduziu a amostra canônica. Verifique o script.")

    if ORIGINAL.exists():
        if ORIGINAL.read_bytes() != dados:
            raise RuntimeError(
                "A amostra original difere da versão canônica. "
                "Nenhum arquivo foi alterado; confira amostras/ocorrencias_rpa.csv."
            )
        print("Comparação com a amostra original: IDENTICA (byte a byte).")
    else:
        print("Amostra original ausente; integridade validada pelo SHA-256 canônico.")

    GERADO.parent.mkdir(parents=True, exist_ok=True)
    GERADO.write_bytes(dados)

    quantos_ids = len({linha[0] for linha in OCORRENCIAS})
    print(f"Arquivo gerado: {GERADO.relative_to(RAIZ)}")
    print(f"Registros: {len(OCORRENCIAS)} | IDs distintos: {quantos_ids} | Duplicatas: {len(OCORRENCIAS) - quantos_ids}")
    print(f"SHA-256: {hash_gerado}")
    print("O CSV original e os resultados existentes no Airflow/Databricks não foram alterados.")


if __name__ == "__main__":
    main()
