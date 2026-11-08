import 'dart:convert';
import 'dart:io';
import 'notebook.dart';

int runNotebookTests() {
  var passed = 0;
  void ensure(bool condition, String description) {
    if (!condition) throw StateError(description);
  }
  void fails(void Function() action) {
    var failed = false;
    try {
      action();
    } catch (_) {
      failed = true;
    }
    ensure(failed, 'Operação inválida deveria falhar');
  }
  void scenario(String name, void Function() action) {
    final temp = Directory.systemTemp.createTempSync('notebook-test-');
    try {
      action();
      passed++;
    } catch (error) {
      throw StateError('Cenário ' + name + ' falhou: ' + error.toString());
    } finally {
      temp.deleteSync(recursive: true);
    }
  }
  Directory fresh() => Directory.systemTemp.createTempSync('notebook-case-');
  void withBook(void Function(Notebook, Directory) action) {
    final folder = fresh();
    try {
      action(Notebook(folder), folder);
    } finally {
      folder.deleteSync(recursive: true);
    }
  }

  scenario('criação e leitura', () => withBook((book, folder) {
    final note = book.create('aula', '# Aula\nConteúdo');
    ensure(note.id == 'aula', 'ID incorreto');
    ensure(book.read('aula').content == '# Aula\nConteúdo', 'Leitura incorreta');
    ensure(folder.listSync().length == 1, 'Arquivo não criado');
  }));

  scenario('título Markdown', () => withBook((book, folder) {
    ensure(book.titleFor('x', '\n## Um título\ntexto') == 'Um título', 'Título');
  }));

  scenario('título vazio usa ID', () => withBook((book, folder) {
    ensure(book.titleFor('x', '\n  \n') == 'x', 'Fallback');
  }));

  scenario('título longo é truncado', () => withBook((book, folder) {
    ensure(book.titleFor('x', '# ' + List.filled(150, 'a').join()).length == 120, 'Tamanho');
  }));

  scenario('tags são únicas e ordenadas', () => withBook((book, folder) {
    ensure(book.extractTags('#zeta #alfa #zeta').join(',') == 'alfa,zeta', 'Tags');
  }));

  scenario('busca ignora maiúsculas', () => withBook((book, folder) {
    book.create('a', '# Aula\nENGENHARIA');
    ensure(book.search('engenharia').length == 1, 'Busca');
  }));

  scenario('busca por título', () => withBook((book, folder) {
    book.create('a', '# Programação');
    ensure(book.search('programação').length == 1, 'Título');
  }));

  scenario('busca por tag', () => withBook((book, folder) {
    book.create('a', '# Aula\n#estudo');
    book.create('b', '# Outra\n#trabalho');
    ensure(book.search('', tag: 'ESTUDO').single.id == 'a', 'Tag');
  }));

  scenario('busca combinada', () => withBook((book, folder) {
    book.create('a', '# Aula\n#estudo Python');
    book.create('b', '# Aula\n#trabalho Python');
    ensure(book.search('python', tag: 'estudo').length == 1, 'Combinação');
  }));

  scenario('paginação determinística', () => withBook((book, folder) {
    book.create('c', 'teste');
    book.create('a', 'teste');
    book.create('b', 'teste');
    ensure(book.search('teste', offset: 1, limit: 1).single.id == 'b', 'Página');
    ensure(book.search('teste', offset: 99).isEmpty, 'Página vazia');
  }));

  scenario('paginação inválida falha', () => withBook((book, folder) {
    fails(() => book.search('x', offset: -1));
    fails(() => book.search('x', limit: 0));
    fails(() => book.search('x', limit: 1001));
  }));

  scenario('busca vazia falha', () => withBook((book, folder) {
    fails(() => book.search('  '));
  }));

  scenario('listagem ordenada', () => withBook((book, folder) {
    book.create('z', 'z');
    book.create('a', 'a');
    ensure(book.list().map((n) => n.id).join(',') == 'a,z', 'Ordem');
  }));

  scenario('atualização substitui conteúdo', () => withBook((book, folder) {
    book.create('a', 'antigo');
    book.update('a', 'novo');
    ensure(book.read('a').content == 'novo', 'Atualização');
  }));

  scenario('atualização exige nota existente', () => withBook((book, folder) {
    fails(() => book.update('ausente', 'novo'));
  }));

  scenario('exclusão remove arquivo', () => withBook((book, folder) {
    book.create('a', 'teste');
    book.delete('a');
    ensure(book.list().isEmpty, 'Exclusão');
    fails(() => book.delete('a'));
  }));

  scenario('ID duplicado é rejeitado', () => withBook((book, folder) {
    book.create('a', 'primeiro');
    fails(() => book.create('a', 'segundo'));
    ensure(book.read('a').content == 'primeiro', 'Sobrescrita');
  }));

  scenario('travessia de diretório é bloqueada', () => withBook((book, folder) {
    fails(() => book.create('../escape', 'perigoso'));
    fails(() => book.create('sub/a', 'perigoso'));
    fails(() => book.read('../escape'));
  }));

  scenario('IDs vazios e com espaços são rejeitados', () => withBook((book, folder) {
    fails(() => book.create('', 'x'));
    fails(() => book.create('com espaço', 'x'));
  }));

  scenario('nota maior que 1 MB é rejeitada', () => withBook((book, folder) {
    fails(() => book.create('a', List.filled(1000001, 'x').join()));
    ensure(book.list().isEmpty, 'Arquivo parcial');
  }));

  scenario('byte NUL é rejeitado', () => withBook((book, folder) {
    fails(() => book.create('a', 'abc\u0000def'));
  }));

  scenario('estatísticas contam notas e tags', () => withBook((book, folder) {
    book.create('a', '#aula #estudo');
    book.create('b', '#estudo');
    final stats = book.stats();
    ensure(stats['notes'] == 2, 'Quantidade');
    ensure((stats['tags'] as Map)['estudo'] == 2, 'Frequência');
  }));

  scenario('exportação JSON é versionada', () => withBook((book, folder) {
    book.create('a', '# Nota');
    final backup = jsonDecode(book.exportJson()) as Map;
    ensure(backup['version'] == 1, 'Versão');
    ensure((backup['notes'] as List).length == 1, 'Conteúdo');
  }));

  scenario('importação restaura Unicode', () => withBook((book, folder) {
    book.create('cafe', '# Café\nAção');
    final backup = book.exportJson();
    book.delete('cafe');
    ensure(book.importJson(backup) == 1, 'Importação');
    ensure(book.read('cafe').content.contains('Café'), 'Unicode');
  }));

  scenario('importação recusa sobrescrever por padrão', () => withBook((book, folder) {
    book.create('a', 'original');
    fails(() => book.importJson(book.exportJson()));
    ensure(book.read('a').content == 'original', 'Preservação');
  }));

  scenario('importação permite sobrescrita explícita', () => withBook((book, folder) {
    book.create('a', 'original');
    final backup = jsonEncode({'version': 1, 'notes': [
      {'id': 'a', 'content': 'atualizado'}
    ]});
    ensure(book.importJson(backup, overwrite: true) == 1, 'Importação');
    ensure(book.read('a').content == 'atualizado', 'Sobrescrita');
  }));

  scenario('importação inválida não cria notas', () => withBook((book, folder) {
    fails(() => book.importJson('{"version":2,"notes":[]}'));
    ensure(book.list().isEmpty, 'Estado alterado');
  }));

  scenario('backup com ID duplicado é rejeitado', () => withBook((book, folder) {
    final backup = jsonEncode({'version': 1, 'notes': [
      {'id': 'a', 'content': 'um'}, {'id': 'a', 'content': 'dois'}
    ]});
    fails(() => book.importJson(backup));
    ensure(book.list().isEmpty, 'Importação parcial');
  }));

  scenario('backup com caminho malicioso é rejeitado', () => withBook((book, folder) {
    final backup = jsonEncode({'version': 1, 'notes': [
      {'id': '../escape', 'content': 'malicioso'}
    ]});
    fails(() => book.importJson(backup));
    ensure(book.list().isEmpty, 'Arquivo criado');
  }));

  scenario('backup com nota inválida não importa parcialmente', () =>
      withBook((book, folder) {
    final backup = jsonEncode({'version': 1, 'notes': [
      {'id': 'a', 'content': 'válido'}, {'id': 'b', 'content': 123}
    ]});
    fails(() => book.importJson(backup));
    ensure(book.list().isEmpty, 'Importação parcial');
  }));

  scenario('pasta ausente é rejeitada', () => withBook((book, folder) {
    folder.deleteSync();
    fails(() => book.list());
    fails(() => book.create('a', 'texto'));
  }));

  scenario('links simbólicos não são lidos', () => withBook((book, folder) {
    final external = File(folder.path + '/real.txt')..writeAsStringSync('segredo');
    Link(folder.path + '/alias.md').createSync(external.path);
    ensure(book.list().isEmpty, 'Link incluído na listagem');
    fails(() => book.read('alias'));
  }));

  scenario('arquivo não Markdown é ignorado', () => withBook((book, folder) {
    File(folder.path + '/nota.txt').writeAsStringSync('texto');
    ensure(book.list().isEmpty, 'Extensão indevida');
  }));

  return passed;
}
