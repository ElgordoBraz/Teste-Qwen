#!/usr/bin/env python3
"""Converte indentacao por espacos dos scripts .gd para TABS (padrao GDScript).

Empilha a coluna de cada linha que abre bloco (termina com ':'). Para cada
linha, o nivel de tab = quantidade de blocos abertos cuja coluna < coluna dela.
Uso: python3 tools/fix_indent.py
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "scripts")


def convert(path: str) -> None:
    lines = open(path).read().split("\n")
    out = []
    stack = []  # colunas de inicio de corpo de bloco ainda abertas
    for line in lines:
        if not line.strip():
            out.append("")
            continue
        n = len(line) - len(line.lstrip(" "))
        s = line.lstrip(" ").rstrip()
        while stack and stack[-1] >= n:
            stack.pop()
        level = len(stack)
        out.append("\t" * level + s)
        if s.endswith(":") and not s.startswith("#"):
            stack.append(n)
    with open(path, "w") as f:
        f.write("\n".join(out))


def main() -> None:
    for fname in sorted(os.listdir(ROOT)):
        if fname.endswith(".gd"):
            p = os.path.join(ROOT, fname)
            convert(p)
            txt = open(p).read()
            bad = sum(1 for l in txt.split("\n") if l.startswith(" "))
            tabs = sum(1 for l in txt.split("\n") if l.startswith("\t"))
            print(f"{fname}: linhas-com-espaco={bad} linhas-com-tab={tabs}")


if __name__ == "__main__":
    main()
