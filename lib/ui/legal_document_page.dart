import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dokumen belum dapat dimuat. Silakan coba lagi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => LegalDocumentScreen(
                              title: title,
                              assetPath: assetPath,
                            ),
                          ),
                        );
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            );
          }

          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: _buildMarkdownBlocks(snapshot.data!),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildMarkdownBlocks(String markdown) {
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];
    var index = 0;

    while (index < lines.length) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        index++;
        continue;
      }

      final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: level == 1 ? 16 : 12, bottom: 8),
            child: _inlineText(
              heading.group(2)!,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: level == 1 ? 22 : (level == 2 ? 18 : 15),
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        );
        index++;
        continue;
      }

      if (line.startsWith('|')) {
        final tableRows = <List<String>>[];
        while (index < lines.length && lines[index].trim().startsWith('|')) {
          final cells = lines[index]
              .trim()
              .replaceAll(RegExp(r'^\||\|$'), '')
              .split('|')
              .map((cell) => cell.trim())
              .toList();
          if (!cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell))) {
            tableRows.add(cells);
          }
          index++;
        }
        if (tableRows.isNotEmpty) {
          widgets.add(_tableCard(tableRows));
          widgets.add(const SizedBox(height: 12));
        }
        continue;
      }

      if (line.startsWith('>')) {
        final quoteLines = <String>[];
        while (index < lines.length && lines[index].trim().startsWith('>')) {
          quoteLines.add(
            lines[index].trim().replaceFirst(RegExp(r'^>\s?'), ''),
          );
          index++;
        }
        widgets.add(_quoteCard(quoteLines.join(' ')));
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      final listItem = RegExp(
        r'^\s*([-*]|\d+\.)\s+(.+)$',
      ).firstMatch(lines[index]);
      if (listItem != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    listItem.group(1) == '-' || listItem.group(1) == '*'
                        ? '•'
                        : listItem.group(1)!,
                    style: const TextStyle(
                      color: Color(0xFF009688),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _inlineText(
                    listItem.group(2)!,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        index++;
        continue;
      }

      final paragraph = <String>[];
      while (index < lines.length) {
        final current = lines[index].trim();
        if (current.isEmpty ||
            RegExp(r'^#{1,3}\s').hasMatch(current) ||
            current.startsWith('|') ||
            current.startsWith('>') ||
            RegExp(r'^\s*([-*]|\d+\.)\s+').hasMatch(lines[index])) {
          break;
        }
        paragraph.add(current);
        index++;
      }
      if (paragraph.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _inlineText(
              paragraph.join(' '),
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _tableCard(List<List<String>> rows) {
    final headers = rows.first;
    return Card(
      margin: const EdgeInsets.only(top: 4),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in rows.skip(1))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var cellIndex = 0; cellIndex < row.length; cellIndex++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _inlineText(
                          '${headers[cellIndex]}: ${row[cellIndex]}',
                          style: TextStyle(
                            color: cellIndex == 0
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF475569),
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: cellIndex == 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    if (row != rows.last)
                      const Divider(height: 12, color: Color(0xFFE2E8F0)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quoteCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _inlineText(
        text,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 13,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _inlineText(String text, {required TextStyle style}) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    var start = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final value = match.group(1) ?? match.group(2)!;
      spans.add(
        TextSpan(
          text: value,
          style: TextStyle(
            fontWeight: match.group(1) != null
                ? FontWeight.bold
                : FontWeight.w600,
            color: match.group(2) != null ? const Color(0xFF047857) : null,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}
