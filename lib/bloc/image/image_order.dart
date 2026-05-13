// lib/bloc/order/save_image_bloc.dart

import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values.dart';
import 'package:marketing/services/provider/current_user.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class SaveImageEvent {}

class UploadOrderImages extends SaveImageEvent {
  final int orderId;
  final int partyId;
  final List<File> files;

  UploadOrderImages({
    required this.orderId,
    required this.partyId,
    required this.files,
  });
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SaveImageState {}

class SaveImageIdle extends SaveImageState {}

class SaveImageUploading extends SaveImageState {}

class SaveImageSuccess extends SaveImageState {
  final String message;
  SaveImageSuccess(this.message);
}

class SaveImageFailure extends SaveImageState {
  final String message;
  SaveImageFailure(this.message);
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class SaveImageBloc extends Bloc<SaveImageEvent, SaveImageState> {
  static const _encoder = Object(); // just for namespacing logs

  SaveImageBloc() : super(SaveImageIdle()) {
    on<UploadOrderImages>(_onUpload);
  }

  static void _log(String msg, {String tag = 'SaveImage'}) =>
      dev.log(msg, name: tag, level: 800);

  Future<void> _onUpload(
    UploadOrderImages event,
    Emitter<SaveImageState> emit,
  ) async {
    emit(SaveImageUploading());

    // ── Build URI with query params ──────────────────────────────────────
    // API: POST /api/v1/Order/SaveImageForOrder
    // Params: orderId, partyId, compId  (passed as query string)
    // Body:   multipart/form-data  →  formFiles[]
    final uri =
        Uri.parse(
          '${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.saveImageForOrder}',
        ).replace(
          queryParameters: {
            'orderId': event.orderId.toString(),
            'partyId': event.partyId.toString(),
            'compId': CurrentUser.compId.toString(),
          },
        );

    // ── Build multipart request ──────────────────────────────────────────
    final request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = '*/*'
      ..headers['Authorization'] = 'Bearer ${CurrentUser.token}';

    for (final file in event.files) {
      final fileName = file.path.split('/').last;
      final mimeType = _mimeType(fileName);
      request.files.add(
        await http.MultipartFile.fromPath(
          'formFiles', // field name from curl
          file.path,
          // Let http package set Content-Type from the file
        ),
      );
      _log('  Attaching: $fileName  ($mimeType)', tag: 'SaveImage.files');
    }

    // ── Log full request ─────────────────────────────────────────────────
    _log('╔════════════════════════════════════════╗');
    _log('║     SAVE IMAGE FOR ORDER ▶ REQUEST      ║');
    _log('╚════════════════════════════════════════╝');
    _log('URL     : $uri');
    _log('OrderId : ${event.orderId}');
    _log('PartyId : ${event.partyId}');
    _log('CompId  : ${CurrentUser.compId}');
    _log('Files   : ${event.files.length} file(s)');
    for (int i = 0; i < event.files.length; i++) {
      _log(
        '  [${i + 1}] ${event.files[i].path.split('/').last}'
        '  (${_mimeType(event.files[i].path.split('/').last)})',
        tag: 'SaveImage.files',
      );
    }
    _log('════════════════════════════════════════');

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      _log('╔════════════════════════════════════════╗');
      _log('║     SAVE IMAGE FOR ORDER ▶ RESPONSE     ║');
      _log('╚════════════════════════════════════════╝');
      _log('Status : ${response.statusCode}');
      _log('Body   : ${response.body}', tag: 'SaveImage.response');
      _log('════════════════════════════════════════');

      if (response.statusCode == 200) {
        emit(SaveImageSuccess('Files uploaded successfully.'));
      } else if (response.statusCode == 401) {
        emit(SaveImageFailure('Session expired. Please login again.'));
      } else {
        emit(
          SaveImageFailure(
            'Upload failed (${response.statusCode}): ${response.body}',
          ),
        );
      }
    } catch (e) {
      _log('Error: $e', tag: 'SaveImage.error');
      emit(SaveImageFailure('Network error: $e'));
    }
  }

  // ── Mime type helper ───────────────────────────────────────────────────────
  static String _mimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
