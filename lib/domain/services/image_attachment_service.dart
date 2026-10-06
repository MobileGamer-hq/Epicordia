import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_attachment_model.dart';

/// Helper service for picking and compressing images for Epi chat.
class ImageAttachmentService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from [source] (camera or gallery) and compresses it
  /// to max 800px on the longest side at 75% JPEG quality.
  static Future<ChatAttachment?> pickAndCompressImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );

      if (pickedFile == null) return null;

      final String fileName = pickedFile.name.isNotEmpty ? pickedFile.name : 'attached_image.jpg';
      Uint8List bytes;

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        try {
          final compressedBytes = await FlutterImageCompress.compressWithFile(
            pickedFile.path,
            minWidth: 800,
            minHeight: 800,
            quality: 75,
            format: CompressFormat.jpeg,
          );
          if (compressedBytes != null && compressedBytes.isNotEmpty) {
            bytes = compressedBytes;
          } else {
            bytes = await pickedFile.readAsBytes();
          }
        } catch (_) {
          bytes = await pickedFile.readAsBytes();
        }
      } else {
        bytes = await pickedFile.readAsBytes();
      }

      final base64Str = base64Encode(bytes);
      final rawMime = pickedFile.mimeType;
      final mimeType = (rawMime != null && rawMime.startsWith('image/'))
          ? rawMime
          : 'image/jpeg';

      return ChatAttachment(
        bytes: bytes,
        base64Data: base64Str,
        mimeType: mimeType,
        fileSize: bytes.length,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
      return null;
    }
  }
}
