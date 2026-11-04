# Caderno Offline

Anotações em Markdown com busca, armazenamento local e exportação.

## Implementado na primeira versão

**Dart — núcleo executável de domínio.** Busca textual em arquivos Markdown locais, ignora links e outros formatos e exporta títulos e nomes das notas em JSON.

## Como executar

Instale Dart SDK 3.5 ou compatível. Não há pacotes externos. Os comandos abaixo partem da raiz do repositório.

```sh
dart run bin/main.dart examples/notas engenharia
```

## Testes

```sh
dart run bin/main.dart --self-test
```

Os testes cobrem invariantes e entradas inválidas. A preparação local não dispõe deste runtime; o workflow em `.github/workflows/ci.yml` executa a validação no GitHub Actions. O resultado de cada execução está na aba Actions, associado ao commit.

## Organização e limites

Código e exemplos: `bin/main.dart e examples/notas/`. Os dados de exemplo são fictícios. As funções de domínio são separadas da leitura de argumentos no mesmo arquivo para manter a primeira versão pequena e revisável.

Busca apenas a pasta imediata e usa conversão Unicode simples para minúsculas; não remove acentos. Edite as notas em seu editor de preferência. Editor Flutter, importação e Drift estão planejados.

A proposta completa de evolução está em `ARQUITETURA.md`. As tecnologias propostas nessa arquitetura não devem ser interpretadas como dependências já implementadas.

## Próximas entregas

- [ ] Editar notas em Markdown — ampliar o núcleo atual até o fluxo completo.
- [ ] Buscar no conteúdo — ampliar o núcleo atual até o fluxo completo.
- [ ] Exportar e importar notas — ampliar o núcleo atual até o fluxo completo.

Licença: ainda não definida.
