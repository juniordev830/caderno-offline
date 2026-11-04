import 'dart:convert';
import 'dart:io';
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
   print('2 cenários OK'); return;
  }
  if(args.length!=2) throw FormatException('Uso: dart run bin/main.dart PASTA TERMO');
  print(const JsonEncoder.withIndent('  ').convert(searchNotes(Directory(args[0]),args[1])));
 } catch(e) {stderr.writeln('Erro: $e'); exitCode=2;}
}
