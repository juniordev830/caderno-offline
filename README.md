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

## Caderno offline ampliado

A busca original foi preservada. A nova classe `Notebook` oferece CRUD de
notas Markdown, títulos, tags, paginação, estatísticas e backup JSON versionado.
Tags no formato `#nome` aceitam de **2 a 32** caracteres ASCII (`A-Z`, `a-z`,
`0-9`, `_` e `-`). Hashtags maiores são ignoradas por completo, sem truncar a
tag e sem gerar resultados incorretos na busca.

```sh
dart run bin/main.dart --self-test
dart run bin/main.dart --notes-list examples/notas
dart run bin/main.dart --notes-search examples/notas engenharia
dart run bin/main.dart --notes-tag examples/notas estudo
dart run bin/main.dart --notes-stats examples/notas
dart run bin/main.dart --notes-export examples/notas > backup.json
dart run bin/main.dart --notes-import examples/notas backup.json
dart run bin/main.dart --notes-create examples/notas nova nota.md
dart run bin/main.dart --notes-update examples/notas nova nota-editada.md
dart run bin/main.dart --notes-read examples/notas nova
dart run bin/main.dart --notes-delete examples/notas nova
```

Os IDs aceitam apenas letras, números, hífen e underscore. Caminhos com `../`,
links simbólicos e arquivos não Markdown são rejeitados ou ignorados.
A gravação usa arquivo temporário e renomeação atômica. O backup JSON
verifica todos os registros antes de iniciar a importação e não sobrescreve
notas existentes por padrão.

**Limitações:** armazenamento local, sem sincronização remota, autenticação
ou criptografia. Até 1 MB por nota e 10 mil notas por caderno; a busca
considera apenas a pasta imediata e é case-insensitive, sem normalização
de acentos. A importação não oferece transação entre múltiplos arquivos
em caso de falha do sistema operacional.

Os testes incluem busca, CRUD, Unicode, tags, paginação, backup, validação
de entrada e proteção contra travessia de diretórios e links simbólicos.

## Importação de backup com limite seguro

A opção explícita `overwrite: true` permite substituir notas já existentes, mas **não ignora o máximo de 10.000 notas**. Antes de qualquer escrita, o importador conta os IDs novos e rejeita um backup que estouraria esse teto, preservando os arquivos atuais. Os testes incluem importações com mais de 10 mil IDs, colisões válidas e ausência de gravação parcial quando a quantidade excede o limite.
