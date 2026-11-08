import 'dart:convert';
import 'dart:io';

class NoteRecord {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime modifiedAt;

  NoteRecord(this.id, this.title, this.content, this.tags, this.modifiedAt);

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'tags': tags,
    'modified_at': modifiedAt.toUtc().toIso8601String(),
    'content': content,
  };
}

class Notebook {
  final Directory folder;
  static const int maxNoteBytes = 1000000;
  static const int maxNotes = 10000;
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,79}$');
  static final RegExp _tagPattern = RegExp(r'(?:^|\s)#([A-Za-z0-9_-]{2,32})');

  Notebook(this.folder);

  String _validateId(String id) {
    if (!_idPattern.hasMatch(id)) {
      throw const FormatException('ID deve conter apenas letras, números, _ e -');
    }
    return id;
  }

  File _file(String id) {
    _validateId(id);
    return File(folder.path + Platform.pathSeparator + id + '.md');
  }

  void _checkFolder() {
    if (!folder.existsSync()) {
      throw const FileSystemException('Pasta de notas inexistente');
    }
    if (FileSystemEntity.typeSync(folder.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FormatException('Pasta simbólica não permitida');
    }
  }

  bool _existsRegular(File file) {
    final type = FileSystemEntity.typeSync(file.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw const FormatException('Links simbólicos não são permitidos');
    }
    if (type == FileSystemEntityType.notFound) return false;
    if (type != FileSystemEntityType.file) {
      throw const FormatException('Caminho não é um arquivo regular');
    }
    return true;
  }

  void _validateContent(String content) {
    if (utf8.encode(content).length > maxNoteBytes) {
      throw const FormatException('Nota maior que 1 MB');
    }
    if (content.contains('\u0000')) {
      throw const FormatException('Conteúdo contém byte NUL');
    }
  }

  List<String> extractTags(String content) {
    final tags = <String>{};
    for (final match in _tagPattern.allMatches(content)) {
      tags.add(match.group(1)!.toLowerCase());
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  String titleFor(String id, String content) {
    for (final line in const LineSplitter().convert(content)) {
      final title = line.replaceFirst(RegExp(r'^#{1,6}\s+'), '').trim();
      if (title.isNotEmpty) return title.length <= 120
          ? title : title.substring(0, 120);
    }
    return id;
  }

  NoteRecord _record(File file) {
    if (!_existsRegular(file)) {
      throw const FileSystemException('Nota não encontrada');
    }
    if (file.lengthSync() > maxNoteBytes) {
      throw const FormatException('Nota maior que 1 MB');
    }
    final content = file.readAsStringSync(encoding: utf8);
    _validateContent(content);
    final id = file.uri.pathSegments.last.replaceFirst(RegExp(r'\.md$'), '');
    return NoteRecord(
      id, titleFor(id, content), content, extractTags(content),
      file.lastModifiedSync().toUtc(),
    );
  }

  NoteRecord read(String id) {
    _checkFolder();
    return _record(_file(id));
  }

  List<NoteRecord> list() {
    _checkFolder();
    final notes = <NoteRecord>[];
    for (final entry in folder.listSync(followLinks: false)) {
      if (entry is! File || !entry.path.toLowerCase().endsWith('.md')) continue;
      final id = entry.uri.pathSegments.last.replaceFirst(RegExp(r'\.md$'), '');
      if (!_idPattern.hasMatch(id)) continue;
      notes.add(_record(entry));
      if (notes.length > maxNotes) {
        throw const FormatException('Limite de 10000 notas excedido');
      }
    }
    notes.sort((a, b) => a.id.compareTo(b.id));
    return notes;
  }

  void _writeAtomic(File destination, String content) {
    _validateContent(content);
    final temp = File(
      destination.path + '.tmp-' + DateTime.now().microsecondsSinceEpoch.toString(),
    );
    try {
      temp.writeAsStringSync(content, encoding: utf8, flush: true);
      temp.renameSync(destination.path);
    } finally {
      if (temp.existsSync()) temp.deleteSync();
    }
  }

  NoteRecord create(String id, String content) {
    _checkFolder();
    final file = _file(id);
    if (_existsRegular(file)) throw const FormatException('Nota já existe');
    if (list().length >= maxNotes) {
      throw const FormatException('Limite de notas atingido');
    }
    _writeAtomic(file, content);
    return read(id);
  }

  NoteRecord update(String id, String content) {
    _checkFolder();
    final file = _file(id);
    if (!_existsRegular(file)) {
      throw const FileSystemException('Nota não encontrada');
    }
    _writeAtomic(file, content);
    return read(id);
  }

  void delete(String id) {
    _checkFolder();
    final file = _file(id);
    if (!_existsRegular(file)) {
      throw const FileSystemException('Nota não encontrada');
    }
    file.deleteSync();
  }

  List<NoteRecord> search(
    String query, {String? tag, int offset = 0, int limit = 100}
  ) {
    if (offset < 0 || limit < 1 || limit > 1000) {
      throw const FormatException('Paginação inválida');
    }
    final term = query.trim().toLowerCase();
    final selectedTag = tag?.trim().toLowerCase();
    if (term.isEmpty && (selectedTag == null || selectedTag.isEmpty)) {
      throw const FormatException('Informe termo ou tag');
    }
    final matches = list().where((note) {
      final textMatches = term.isEmpty ||
          note.content.toLowerCase().contains(term) ||
          note.title.toLowerCase().contains(term);
      final tagMatches = selectedTag == null || selectedTag.isEmpty ||
          note.tags.contains(selectedTag);
      return textMatches && tagMatches;
    }).toList();
    if (offset >= matches.length) return [];
    return matches.skip(offset).take(limit).toList();
  }

  Map<String, Object> stats() {
    final notes = list();
    final tags = <String, int>{};
    var bytes = 0;
    for (final note in notes) {
      bytes += utf8.encode(note.content).length;
      for (final tag in note.tags) {
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
    }
    final orderedTags = Map.fromEntries(
      tags.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return {'notes': notes.length, 'bytes': bytes, 'tags': orderedTags};
  }

  String exportJson() {
    final notes = list();
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'notes': notes.map((note) => {
        'id': note.id,
        'content': note.content,
      }).toList(),
    });
  }

  int importJson(String source, {bool overwrite = false}) {
    _checkFolder();
    final data = jsonDecode(source);
    if (data is! Map || data['version'] != 1 || data['notes'] is! List) {
      throw const FormatException('Backup JSON inválido');
    }
    final incoming = <String, String>{};
    for (final item in data['notes'] as List) {
      if (item is! Map || item['id'] is! String || item['content'] is! String) {
        throw const FormatException('Nota do backup inválida');
      }
      final id = _validateId(item['id'] as String);
      final content = item['content'] as String;
      _validateContent(content);
      if (incoming.containsKey(id)) {
        throw const FormatException('ID duplicado no backup');
      }
      incoming[id] = content;
    }
    if (incoming.length + list().length > maxNotes && !overwrite) {
      throw const FormatException('Backup excede limite de notas');
    }
    for (final id in incoming.keys) {
      if (_existsRegular(_file(id)) && !overwrite) {
        throw const FormatException('Backup conflita com nota existente');
      }
    }
    for (final entry in incoming.entries) {
      _writeAtomic(_file(entry.key), entry.value);
    }
    return incoming.length;
  }
}
