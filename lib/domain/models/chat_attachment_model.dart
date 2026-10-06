import 'dart:typed_data';

/// Attachment model representing a compressed image ready to send with an Epi chat message.
class ChatAttachment {
  final Uint8List bytes;
  final String base64Data;
  final String mimeType;
  final int fileSize;
  final String fileName;

  const ChatAttachment({
    required this.bytes,
    required this.base64Data,
    required this.mimeType,
    required this.fileSize,
    required this.fileName,
  });

  /// Formatted size display (e.g. "145.2 KB")
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
