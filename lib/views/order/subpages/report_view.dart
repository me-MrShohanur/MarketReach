import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:marketing/bloc/report/report.dart';
import 'package:marketing/services/models/report_model.dart';

// ─── Enum ─────────────────────────────────────────────────────────────────────

enum _PdfStatus { idle, downloading, ready, error }

// ─── ReportView ───────────────────────────────────────────────────────────────

class ReportView extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const ReportView({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
  });

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  // ── Date state ────────────────────────────────────────────────────────────
  late DateTime _from;
  late DateTime _to;

  // ── PDF state ─────────────────────────────────────────────────────────────
  _PdfStatus _pdfStatus = _PdfStatus.idle;
  String? _pdfPath;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.initialStartDate;
    _to = widget.initialEndDate;

    // BlocProvider fires LoadReport before this widget mounts, so
    // BlocListener misses the first ReportReady. Read current state once
    // after the first frame and start the download manually.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ReportState state = context.read<ReportBloc>().state;
      if (state is ReportReady) {
        _downloadPdf(state.reportUri);
      }
    });
  }

  // ── Download PDF ──────────────────────────────────────────────────────────

  Future<void> _downloadPdf(Uri uri) async {
    if (!mounted) return;

    setState(() {
      _pdfStatus = _PdfStatus.downloading;
      _pdfPath = null;
      _errorMessage = null;
      _totalPages = 0;
      _currentPage = 0;
    });

    try {
      log('Downloading: $uri', name: 'ReportView');

      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Server returned status ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('Server returned an empty response.');
      }

      final Directory dir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File('${dir.path}/report_$timestamp.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      log(
        'PDF saved: ${file.path} (${response.bodyBytes.length} bytes)',
        name: 'ReportView',
      );

      if (!mounted) return;
      setState(() {
        _pdfPath = file.path;
        _pdfStatus = _PdfStatus.ready;
      });
    } catch (e) {
      log('Download error: $e', name: 'ReportView');
      if (!mounted) return;
      setState(() {
        _pdfStatus = _PdfStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  // ── Date range picker ─────────────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (BuildContext ctx, Widget? child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _from = picked.start;
      _to = picked.end;
    });

    context.read<ReportBloc>().add(
      ChangeReportDates(startDate: picked.start, endDate: picked.end),
    );
  }

  // ── Retry ─────────────────────────────────────────────────────────────────

  void _onRetry() {
    final ReportState blocState = context.read<ReportBloc>().state;
    if (blocState is ReportReady) {
      _downloadPdf(blocState.reportUri);
    } else {
      context.read<ReportBloc>().add(
        ChangeReportDates(startDate: _from, endDate: _to),
      );
    }
  }

  // ── Label formatter ───────────────────────────────────────────────────────

  static String _labelFmt(DateTime d) {
    const List<String> months = <String>[
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  int get _dayCount => _to.difference(_from).inDays + 1;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (BuildContext context, ReportState state) {
        if (state is ReportReady) {
          _downloadPdf(state.reportUri);
        } else if (state is ReportError) {
          if (!mounted) return;
          setState(() {
            _pdfStatus = _PdfStatus.error;
            _errorMessage = state.message;
          });
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ── Header ────────────────────────────────────────────────
                _ReportHeader(
                  from: _from,
                  to: _to,
                  labelFmt: _labelFmt,
                  onDateTap: _pickDateRange,
                ),

                const SizedBox(height: 16),

                // ── Date strip ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _StripTile(
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFF2196F3),
                          iconBg: const Color(0xFFE3F2FD),
                          accentColor: const Color(0xFF2196F3),
                          label: 'From',
                          value: _labelFmt(_from),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StripTile(
                          icon: Icons.event_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          iconBg: const Color(0xFFE8F5E9),
                          accentColor: const Color(0xFF4CAF50),
                          label: 'To',
                          value: _labelFmt(_to),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StripTile(
                        icon: Icons.date_range_rounded,
                        iconColor: const Color(0xFFFFC107),
                        iconBg: const Color(0xFFFFF8E1),
                        accentColor: const Color(0xFFFFC107),
                        label: 'Days',
                        value: '$_dayCount',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Page counter ──────────────────────────────────────────
                if (_pdfStatus == _PdfStatus.ready && _totalPages > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: BlocBuilder<ReportBloc, ReportState>(
                    builder: (BuildContext context, ReportState blocState) {
                      // BLoC is still computing the URI
                      if (blocState is ReportLoading) {
                        return const _LoadingView(
                          message: 'Building report\u2026',
                        );
                      }

                      switch (_pdfStatus) {
                        case _PdfStatus.idle:
                          return const _LoadingView(message: 'Preparing\u2026');

                        case _PdfStatus.downloading:
                          return const _LoadingView(
                            message: 'Downloading PDF\u2026',
                          );

                        case _PdfStatus.error:
                          return _ErrorView(
                            message: _errorMessage ?? 'Unknown error.',
                            onRetry: _onRetry,
                          );

                        case _PdfStatus.ready:
                          return _PdfCard(
                            path: _pdfPath!,
                            onRender: (int pages) {
                              setState(() => _totalPages = pages);
                            },
                            onPageChanged: (int page, int total) {
                              setState(() => _currentPage = page);
                            },
                            onError: (dynamic err) {
                              if (!mounted) return;
                              setState(() {
                                _pdfStatus = _PdfStatus.error;
                                _errorMessage = err.toString();
                              });
                            },
                          );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ReportHeader extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final String Function(DateTime) labelFmt;
  final VoidCallback onDateTap;

  const _ReportHeader({
    required this.from,
    required this.to,
    required this.labelFmt,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Back button + title
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Orders',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Date picker button
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        labelFmt(from),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '\u2192 ${labelFmt(to)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Strip Tile ───────────────────────────────────────────────────────────────

class _StripTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color accentColor;
  final String label;
  final String value;

  const _StripTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.accentColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    letterSpacing: 0.1,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PDF Card ─────────────────────────────────────────────────────────────────

class _PdfCard extends StatelessWidget {
  final String path;
  final void Function(int pages) onRender;
  final void Function(int page, int total) onPageChanged;
  final void Function(dynamic error) onError;

  const _PdfCard({
    required this.path,
    required this.onRender,
    required this.onPageChanged,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: Color(0xFF2196F3), width: 3),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: PDFView(
          filePath: path,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          fitEachPage: true,
          fitPolicy: FitPolicy.BOTH,
          backgroundColor: Colors.white,
          // onRender: onRender,
          // onPageChanged: onPageChanged,
          onError: onError,
          onPageError: (int? page, dynamic error) => onError(error),
        ),
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: AnimatedBuilder(
        animation: _animation,
        // Pass the expensive subtree as child so it is built only once.
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(color: Color(0xFF2196F3), width: 3),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fetching data for selected period',
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ),
        ),
        builder: (BuildContext context, Widget? child) {
          return Opacity(opacity: _animation.value, child: child);
        },
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load report',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
