import 'dart:convert';
import 'dart:io';
import 'notebook.dart';
import 'notebook_test.dart';
List<Map<String,String>> searchNotes(Directory folder,String query) {
 if(!folder.existsSync() || query.trim().isEmpty) throw FormatException('Pasta e termo de busca são obrigatórios');
 final results=<Map<String,String>>[];
 for(final entry in folder.listSync(followLinks:false)) {
  if(entry is! File || !entry.path.toLowerCase().endsWith('.md')) continue;
  if(entry.lengthSync()>1000000) throw FormatException('Nota maior que 1 MB');
  final text=entry.readAsStringSync();
  if(text.toLowerCase().contains(query.toLowerCase())) results.add({'arquivo':entry.uri.pathSegments.last,'titulo':text.split('\n').first.replaceFirst(RegExp(r'^#+\s*'),'').trim()});
 }
 results.sort((a,b)=>a['arquivo']!.compareTo(b['arquivo']!)); return results;
}
void main(List<String> args) {
 try {
  if(args.length==1 && args[0]=='--self-test') {
   final temp=Directory.systemTemp.createTempSync('caderno-');
   try {
    File('${temp.path}/a.md').writeAsStringSync('# Aula\nEstudo de Rust');
    File('${temp.path}/b.txt').writeAsStringSync('Rust');
    if(searchNotes(temp,'rust').length!=1 || searchNotes(temp,'ausente').isNotEmpty) throw StateError('Teste falhou');
   } finally {temp.deleteSync(recursive:true);}
   print('2 cenários originais + ' + runNotebookTests().toString() + ' cenários de notebook OK'); return;
  }
  if(args.isNotEmpty && args[0].startsWith('--notes-')) {
   if(args.length<2) throw FormatException('Informe a pasta do caderno');
   final book=Notebook(Directory(args[1]));
   final json=const JsonEncoder.withIndent('  ');
   switch(args[0]) {
    case '--notes-list':
     print(json.convert(book.list().map((n)=>n.toJson()).toList()));
     return;
    case '--notes-stats':
     print(json.convert(book.stats()));
     return;
    case '--notes-export':
     print(book.exportJson());
     return;
    case '--notes-search':
     if(args.length!=3) throw FormatException('Informe o termo de busca');
     print(json.convert(book.search(args[2]).map((n)=>n.toJson()).toList()));
     return;
    case '--notes-tag':
     if(args.length!=3) throw FormatException('Informe a tag');
     print(json.convert(book.search('',tag:args[2]).map((n)=>n.toJson()).toList()));
     return;
    case '--notes-backlinks':
     if(args.length!=3) throw FormatException('Informe o ID da nota alvo');
     print(json.convert(book.backlinks(args[2]).map((n)=>n.toJson()).toList()));
     return;
    case '--notes-read':
     if(args.length!=3) throw FormatException('Informe o ID da nota');
     print(json.convert(book.read(args[2]).toJson()));
     return;
    case '--notes-delete':
     if(args.length!=3) throw FormatException('Informe o ID da nota');
     book.delete(args[2]);
     print('Nota excluída');
     return;
    case '--notes-import':
     if(args.length!=3) throw FormatException('Informe o backup JSON');
     print('Notas importadas: ' + book.importJson(File(args[2]).readAsStringSync()).toString());
     return;
    case '--notes-create':
    case '--notes-update':
     if(args.length!=4) throw FormatException('Informe ID e arquivo Markdown');
     final text=File(args[3]).readAsStringSync();
     final note=args[0]=='--notes-create'
       ? book.create(args[2],text) : book.update(args[2],text);
     print(json.convert(note.toJson()));
     return;
    default:
     throw FormatException('Comando de caderno desconhecido');
   }
  }
  if(args.length!=2) throw FormatException('Uso: dart run bin/main.dart PASTA TERMO');
  print(const JsonEncoder.withIndent('  ').convert(searchNotes(Directory(args[0]),args[1])));
 } catch(e) {stderr.writeln('Erro: $e'); exitCode=2;}
}
