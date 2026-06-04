import 'dart:convert';
import 'dart:typed_data';

/// Builds a base64 data URL using the image's actual byte signature.
String imageBytesToDataUrl(Uint8List bytes) {
  return 'data:${detectImageMimeType(bytes)};base64,${base64Encode(bytes)}';
}

String detectImageMimeType(Uint8List bytes) {
  if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) {
    return 'image/jpeg';
  }

  if (_startsWith(bytes, const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ])) {
    return 'image/png';
  }

  if (_startsWith(bytes, const [0x47, 0x49, 0x46, 0x38])) {
    return 'image/gif';
  }

  if (bytes.length >= 12 &&
      _startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }

  if (bytes.length >= 12 &&
      bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70) {
    final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    if (brand == 'heic' ||
        brand == 'heix' ||
        brand == 'hevc' ||
        brand == 'hevx' ||
        brand == 'mif1' ||
        brand == 'msf1') {
      return 'image/heic';
    }
  }

  return 'image/jpeg';
}

bool _startsWith(Uint8List bytes, List<int> signature) {
  if (bytes.length < signature.length) {
    return false;
  }

  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) {
      return false;
    }
  }

  return true;
}
