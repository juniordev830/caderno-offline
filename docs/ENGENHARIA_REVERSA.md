# Engenharia reversa e estudo — Caderno Offline

## Objetivo e fluxo

Anotações Markdown com consulta e armazenamento local. bin/main.dart recebe o comando e Notebook em bin/notebook.dart valida a pasta e o conteúdo antes de gravar.

**Tecnologias identificadas** · Dart.

**Revisão de referência** · `7d85c52c4f75`.

## Mapa do código

| Caminho | Papel de leitura | Símbolos selecionados |
| --- | --- | --- |
| [bin/main.dart](../bin/main.dart) | Ponto de leitura para entrada ou composição | `main` |
| [bin/notebook.dart](../bin/notebook.dart) | Implementação | `NoteRecord`, `Notebook`, `_checkFolder`, `_validateContent`, `_writeAtomic`, `delete` |

## Configuração e referências

Ambiente e dependências: [pubspec.yaml](../pubspec.yaml).

Referências existentes: [ARQUITETURA.md](../ARQUITETURA.md), [docs/GUIA_DE_VALIDACAO.md](GUIA_DE_VALIDACAO.md).

## Roteiro de estudo e desenvolvimento

1. Comece pelo fluxo descrito acima e localize seus pontos de entrada no mapa. Acompanhe uma entrada válida até a transformação ou a resposta.
2. Abra um teste relacionado ao fluxo e descreva qual regra ele protege. Compare o tratamento esperado para entradas válidas, inválidas e nos limites.
3. Ao adicionar uma regra, determine qual módulo controla o dado e cubra o caso nesse nível. Em seguida, confira o efeito no comando, na API ou na interface de entrada.

**Pergunta de entrevista**

Como garantir que uma edição incompleta não comprometa a nota armazenada?

## Testes versionados

Arquivos para começar a leitura dos cenários de teste: [bin/notebook_test.dart](../bin/notebook_test.dart).

Os comandos e versões de runtime usados no CI ficam em [.github/workflows/ci.yml](../.github/workflows/ci.yml).

[Voltar ao README](../README.md).
