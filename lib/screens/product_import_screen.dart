import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';

class ProductImportScreen extends StatefulWidget {
  const ProductImportScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends State<ProductImportScreen> {
  bool _importing = false;
  ImportSummary? _summary;
  String? _selectedPath;

  Future<void> _runImport({
    required String content,
    required String sourceLabel,
  }) async {
    setState(() {
      _selectedPath = sourceLabel;
      _importing = true;
      _summary = null;
    });

    try {
      final rows = _parseDelimitedText(content);
      final summary = await widget.repo.importProducts(rows);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _importing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ice aktarma hatasi: $error')),
      );
    }
  }

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final content = await File(path).readAsString();
    await _runImport(content: content, sourceLabel: path);
  }

  Future<void> _importSampleCsv() async {
    final content = await rootBundle.loadString('ornek_urun_import.csv');
    await _runImport(
      content: content,
      sourceLabel: 'Uygulama icindeki ornek CSV',
    );
  }

  List<Map<String, String>> _parseDelimitedText(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final delimiter = _detectDelimiter(lines.first);
    final headers = lines.first
        .split(delimiter)
        .map((item) => item.trim().toLowerCase())
        .toList();

    return lines.skip(1).map((line) {
      final values = line.split(delimiter).map((item) => item.trim()).toList();
      final row = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        row[headers[i]] = i < values.length ? values[i] : '';
      }
      return row;
    }).toList();
  }

  String _detectDelimiter(String line) {
    if (line.contains(';')) return ';';
    if (line.contains('\t')) return '\t';
    return ',';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Toplu Urun Ice Aktar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Desteklenen format',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'CSV veya TXT dosyasi kullan. Excel dosyasini CSV olarak kaydedip ice aktarabilirsin.',
                  ),
                  SizedBox(height: 12),
                  SelectableText(
                    'code,name,brand,material_group,shelf_location,unit,sale_price,min_stock,initial_stock,last_cost',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hizli demo kurulumu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Muadil urun asistani ve toplu aktarimi aninda denemek icin hazir ornek CSV verisini tek tikla yukleyebilirsin.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: _importing ? null : _importSampleCsv,
                    icon: const Icon(Icons.bolt_rounded),
                    label: Text(
                      _importing
                          ? 'Ornek veri yukleniyor...'
                          : 'Ornek CSV Yukle',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _importing ? null : _pickAndImport,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_importing ? 'Ice aktariliyor...' : 'Dosya Sec ve Ice Aktar'),
          ),
          if (_selectedPath != null) ...[
            const SizedBox(height: 12),
            Text('Secilen dosya: $_selectedPath'),
          ],
          if (summary != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sonuc',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Aktarilan: ${summary.importedCount}'),
                    Text('Atlanan: ${summary.skippedCount}'),
                    if (summary.messages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Mesajlar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      for (final message in summary.messages.take(20))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(message),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
