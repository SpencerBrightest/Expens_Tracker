import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/expense.dart';

/// Builds a structured, AI-style expense narrative and exports it as a PDF.
class ExpenseReportService {
  String generateNarrative({
    required Expense expense,
    required String categoryName,
  }) {
    final amount = NumberFormat.currency(
      locale: 'fr_CM',
      name: 'XAF',
      symbol: 'XAF ',
    ).format(expense.amount);
    final date = DateFormat('d MMMM yyyy').format(expense.date);
    final subcategory = expense.subcategory.trim().isNotEmpty
        ? expense.subcategory.trim()
        : 'General spend';
    final note = expense.note.trim().isNotEmpty
        ? expense.note.trim()
        : 'No additional description was provided for this expense.';

    final report = [
      'Expense Report',
      '',
      '1. Overview',
      'This report tracks a transaction under $categoryName for $subcategory. The payment total is $amount and it was recorded on $date. The entry reflects a specific financial decision and should be understood within the user\'s broader monthly budget and spending priorities.',
      '',
      '2. Category context',
      'The category assigned to this expense is $categoryName, while the subcategory $subcategory adds more detail about the purpose of the spending. This structure helps separate routine costs from unusual ones and allows the user to compare similar purchases over time. It also shows where the expense fits within the broader plan for personal or business spending.',
      '',
      '3. Notes and purpose',
      'The description attached to this expense states: $note. This detail matters because it explains why the payment happened and turns a simple financial line item into a meaningful story. By recording the reason behind the purchase, the user creates a stronger audit trail and can better monitor whether the spending aligns with planned priorities.',
      '',
      '4. Financial interpretation',
      'From a budgeting perspective, this transaction contributes to category totals and can be reviewed alongside similar purchases to reveal patterns in behavior. It shows how the user is allocating resources, how much attention is being placed on specific categories, and whether the spending remains aligned with short-term or long-term financial goals. The more clearly the purpose is documented, the easier it becomes to assess the cost and improve future planning.',
      '',
      '5. Summary',
      'In summary, this expense is not only a payment entry but also a useful planning signal. It captures the amount, the category, the subcategory, and the reason behind the purchase in a clear, structured format that supports better financial control, stronger record keeping, and more informed decision-making over time.',
    ].join('\n\n');

    final words = report
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.length > 360) {
      return report.substring(0, report.length - 150);
    }
    return report;
  }

  Future<Uint8List> buildPdfBytes({
    required Expense expense,
    required String categoryName,
  }) async {
    final report = generateNarrative(
      expense: expense,
      categoryName: categoryName,
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Expense Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Category: $categoryName'),
                    pw.Text(
                      'Subcategory: ${expense.subcategory.trim().isNotEmpty ? expense.subcategory.trim() : 'General spend'}',
                    ),
                    pw.Text(
                      'Amount: ${NumberFormat.currency(locale: 'fr_CM', name: 'XAF', symbol: 'XAF ').format(expense.amount)}',
                    ),
                    pw.Text(
                      'Date: ${DateFormat('d MMMM yyyy').format(expense.date)}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                report,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
