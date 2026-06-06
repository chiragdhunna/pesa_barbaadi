import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pesa_barbaadi/models/fuel_entry.dart';
import 'package:pesa_barbaadi/utils/formatters.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

class ExportService {
  /// Filters entries by a given DateTimeRange.
  List<FuelEntry> _filterEntries(
      List<FuelEntry> entries, DateTimeRange? range) {
    if (range == null) return entries;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end =
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return entries
        .where((e) =>
            (e.date.isAfter(start) || e.date.isAtSameMomentAs(start)) &&
            (e.date.isBefore(end) || e.date.isAtSameMomentAs(end)))
        .toList();
  }

  /// Exports entries to an Excel file using syncfusion_flutter_xlsio.
  Future<void> exportToExcel(
    List<FuelEntry> entries,
    String myName,
    String friendName,
    DateTimeRange? range,
  ) async {
    final filteredEntries = _filterEntries(entries, range);
    if (filteredEntries.isEmpty) return;

    final xls.Workbook workbook = xls.Workbook();

    // Define header style outside the loop
    final xls.Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.backColor = '#5B7FFF';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;

    // Group entries by month
    final Map<String, List<FuelEntry>> groupedEntries = {};
    for (var entry in filteredEntries) {
      final monthYear = DateFormat('MMMM yyyy').format(entry.date);
      groupedEntries.putIfAbsent(monthYear, () => []).add(entry);
    }

    // Create a worksheet for each month
    int sheetIndex = 0;
    groupedEntries.forEach((month, monthEntries) {
      final xls.Worksheet sheet = sheetIndex == 0
          ? workbook.worksheets[0]
          : workbook.worksheets.addWithName(month);
      if (sheetIndex == 0) sheet.name = month;
      sheetIndex++;

      // Set headers
      sheet.getRangeByIndex(1, 1).setText('Date');
      sheet.getRangeByIndex(1, 2).setText('Paid By');
      sheet.getRangeByIndex(1, 3).setText('Amount (₹)');
      sheet.getRangeByIndex(1, 4).setText('Type');
      sheet.getRangeByIndex(1, 5).setText('Note');
      sheet.getRangeByName('A1:E1').cellStyle = headerStyle;

      double youTotal = 0;
      double friendTotal = 0;

      // Fill entries
      for (int i = 0; i < monthEntries.length; i++) {
        final entry = monthEntries[i];
        final row = i + 2;
        sheet
            .getRangeByIndex(row, 1)
            .setText(AppFormatters.formatDate(entry.date));
        sheet.getRangeByIndex(row, 2).setText(entry.paidByName);
        sheet.getRangeByIndex(row, 3).setNumber(entry.amount);
        sheet.getRangeByIndex(row, 4).setText(entry.type);
        sheet.getRangeByIndex(row, 5).setText(entry.note ?? '');

        if (entry.paidByName == myName) {
          youTotal += entry.amount;
        } else {
          friendTotal += entry.amount;
        }
      }

      // Totals row
      final int totalRow = monthEntries.length + 3;
      sheet.getRangeByIndex(totalRow, 1).setText('Totals');
      sheet.getRangeByIndex(totalRow, 1).cellStyle.bold = true;

      sheet.getRangeByIndex(totalRow + 1, 1).setText('$myName Total:');
      sheet.getRangeByIndex(totalRow + 1, 3).setNumber(youTotal);

      sheet.getRangeByIndex(totalRow + 2, 1).setText('$friendName Total:');
      sheet.getRangeByIndex(totalRow + 2, 3).setNumber(friendTotal);

      final grandTotal = youTotal + friendTotal;
      sheet.getRangeByIndex(totalRow + 3, 1).setText('Grand Total:');
      sheet.getRangeByIndex(totalRow + 3, 3).setNumber(grandTotal);

      final fairShare = grandTotal / 2;
      final balance = youTotal - fairShare;
      sheet.getRangeByIndex(totalRow + 4, 1).setText('Balance:');
      sheet.getRangeByIndex(totalRow + 4, 3).setText(balance > 0
          ? '$friendName owes you ₹${balance.abs().toStringAsFixed(2)}'
          : balance < 0
              ? 'You owe $friendName ₹${balance.abs().toStringAsFixed(2)}'
              : 'Settled');

      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);
      sheet.autoFitColumn(5);
    });

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final String path = (await getApplicationDocumentsDirectory()).path;
    final String fileName =
        '$path/Fuel_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final File file = File(fileName);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(fileName)], text: 'Excel Fuel Report');
  }

  /// Exports entries to a PDF file using the pdf package.
  Future<void> exportToPdf(
    List<FuelEntry> entries,
    String myName,
    String friendName,
    DateTimeRange? range,
  ) async {
    final filteredEntries = _filterEntries(entries, range);
    if (filteredEntries.isEmpty) return;

    final pdf = pw.Document();

    double youTotal = 0;
    double friendTotal = 0;
    for (var e in filteredEntries) {
      if (e.paidByName == myName) {
        youTotal += e.amount;
      } else {
        friendTotal += e.amount;
      }
    }
    final total = youTotal + friendTotal;
    final fairShare = total / 2;
    final balance = youTotal - fairShare;

    // Summary Page
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Scooty Fuel Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Range: ${range != null ? "${AppFormatters.formatDate(range.start)} - ${AppFormatters.formatDate(range.end)}" : "All Time"}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Summary',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Spent:'),
                          pw.Text('₹${total.toStringAsFixed(2)}')
                        ]),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$myName Paid:'),
                          pw.Text('₹${youTotal.toStringAsFixed(2)}')
                        ]),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$friendName Paid:'),
                          pw.Text('₹${friendTotal.toStringAsFixed(2)}')
                        ]),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Status:',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            balance > 0
                                ? '$friendName owes you ₹${balance.abs().toStringAsFixed(2)}'
                                : balance < 0
                                    ? 'You owe $friendName ₹${balance.abs().toStringAsFixed(2)}'
                                    : 'Settled',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                    'Generated by Pesa Barbaadi on ${AppFormatters.formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    // Entries Table Page(s)
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text('All Entries',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey900),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              headers: ['Date', 'Paid By', 'Amount', 'Type', 'Note'],
              data: filteredEntries
                  .map((e) => [
                        AppFormatters.formatDate(e.date),
                        e.paidByName,
                        '₹${e.amount}',
                        e.type,
                        e.note ?? ''
                      ])
                  .toList(),
            ),
          ];
        },
      ),
    );

    final String path = (await getApplicationDocumentsDirectory()).path;
    final String fileName =
        '$path/Fuel_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(fileName);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(fileName)], text: 'PDF Fuel Report');
  }

  /// Exports entries to a CSV file manually.
  Future<void> exportToCsv(
      List<FuelEntry> entries, DateTimeRange? range) async {
    final filteredEntries = _filterEntries(entries, range);
    if (filteredEntries.isEmpty) return;

    final StringBuffer csv = StringBuffer();
    csv.writeln('id,paidByName,amount,date,type,note');

    for (var e in filteredEntries) {
      // Quote fields to handle commas
      final String paidByName = '"${e.paidByName.replaceAll('"', '""')}"';
      final String note = '"${(e.note ?? "").replaceAll('"', '""')}"';
      csv.writeln(
          '${e.id},$paidByName,${e.amount},${e.date.toIso8601String()},${e.type},$note');
    }

    final String path = (await getApplicationDocumentsDirectory()).path;
    final String fileName =
        '$path/Fuel_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final File file = File(fileName);
    await file.writeAsString(csv.toString());

    await Share.shareXFiles([XFile(fileName)], text: 'CSV Fuel Report');
  }
}
