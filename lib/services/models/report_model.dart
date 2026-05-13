// lib/services/models/report_model.dart

import 'package:marketing/services/provider/current_user.dart';

class ReportParams {
  final int reportId;
  final String exportType;
  final DateTime startDate;
  final DateTime endDate;
  final int accountId;
  final int ledgerType;

  const ReportParams({
    this.reportId = 105,
    this.exportType = 'pdf',
    required this.startDate,
    required this.endDate,
    this.accountId = 3,
    this.ledgerType = 1,
  });

  // Formats DateTime to "yyyyMMdd" e.g. 20260101
  static String _fmt(DateTime d) =>
      '${d.year}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  Uri buildUri() {
    final String start = _fmt(startDate);
    final String end = _fmt(endDate);

    return Uri.parse(
      'http://103.125.253.59:3004/api/erp/commercialRpt/'
      '?ReportId=$reportId'
      '&ExportType=$exportType'
      '&Between=$start'
      '&StartDate=$start'
      '&EndDate=$end'
      '&LedgerID=${CurrentUser.customerID}'
      '&AccountId=$accountId'
      '&LedgerType=$ledgerType'
      '&And=$end'
      '&CompId=${CurrentUser.compId}'
      '&BranchId=${CurrentUser.branchId}',
    );
  }

  ReportParams copyWith({
    int? reportId,
    String? exportType,
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    int? ledgerType,
  }) {
    return ReportParams(
      reportId: reportId ?? this.reportId,
      exportType: exportType ?? this.exportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountId: accountId ?? this.accountId,
      ledgerType: ledgerType ?? this.ledgerType,
    );
  }
}
