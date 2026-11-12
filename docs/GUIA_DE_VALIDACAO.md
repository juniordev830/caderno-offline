# Caderno Offline: guia técnico

## Escopo real

CLI Dart de busca em Markdown local e exportação; ainda sem interface Flutter.

## Arquivos relacionados

`bin/main.dart`, `examples/notas/`, `pubspec.yaml` e `ARQUITETURA.md`.

## Procedimento de validação

`dart run bin/main.dart examples/notas engenharia` e `dart run bin/main.dart --self-test`.

Se algo não puder ser executado, registrar como pendente, sem afirmar sucesso. Preservar resultados reais de CI vinculados aos commits relevantes.

## Casos para revisão

Cobrir caminhos fora da pasta permitida, arquivos não Markdown, Unicode, notas vazias e serialização JSON segura.

## Próxima evolução

Manter notas pessoais fora do Git; para sincronização futura, definir limites de armazenamento e conflitos.

## Para submeter uma mudança

- [ ] Especificar problema e comportamento esperado.
- [ ] Anexar evidência de teste ou reprodução real.
- [ ] Revisar acessibilidade, privacidade e licenças quando aplicável.
- [ ] Submeter em branch separada e revisar antes de merge.
