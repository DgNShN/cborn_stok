import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_models.dart';

class PdfService {
  Future<String> createDispatchPdf({
    required SaleRecord sale,
    required List<SaleLine> items,
  }) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL');
    final date = DateFormat('dd.MM.yyyy HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'SEVK IRSALIYESI',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Belge No: ${sale.invoiceNo}'),
          pw.Text('Tarih: ${date.format(sale.createdAt)}'),
          pw.Text(
            'Musteri: ${sale.customerName.isEmpty ? 'Genel Musteri' : sale.customerName}',
          ),
          pw.Text(
            'Telefon: ${sale.customerPhone.isEmpty ? '-' : sale.customerPhone}',
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: const ['Kod', 'Urun', 'Miktar', 'Birim Fiyat', 'Toplam'],
            data: items
                .map(
                  (item) => [
                    item.productCode,
                    item.productName,
                    item.quantity.toStringAsFixed(2),
                    currency.format(item.unitPrice),
                    currency.format(item.lineTotal),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Genel Toplam: ${currency.format(sale.totalAmount)}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Teslim Eden'),
                  pw.SizedBox(height: 24),
                  pw.Text('.........................'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Teslim Alan'),
                  pw.SizedBox(height: 24),
                  pw.Text('.........................'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final baseDir = await getApplicationDocumentsDirectory();
    final invoiceDir = Directory(p.join(baseDir.path, 'invoices'));
    if (!await invoiceDir.exists()) {
      await invoiceDir.create(recursive: true);
    }

    final file = File(p.join(invoiceDir.path, '${sale.invoiceNo}.pdf'));
    await file.writeAsBytes(await doc.save());
    return file.path;
  }
}
