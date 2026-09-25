import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class CapturedPantryImage {
  final Uint8List bytes;
  final String mimeType;
  final File file;

  CapturedPantryImage(
      {required this.bytes, required this.mimeType, required this.file});
}

/// Handles native camera/gallery permissions via image_picker, then
/// downscales + re-encodes the photo as JPEG before it's sent to Gemini
/// (keeps upload size small and requests fast).
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<CapturedPantryImage?> pickFromCamera() =>
      _pickAndProcess(ImageSource.camera);

  Future<CapturedPantryImage?> pickFromGallery() =>
      _pickAndProcess(ImageSource.gallery);

  Future<CapturedPantryImage?> _pickAndProcess(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final rawBytes = await picked.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw Exception('Could not read that image. Please try another one.');
    }

    // Downscale further if the longest edge is still large, to keep the
    // multimodal request light.
    img.Image resized = decoded;
    const maxEdge = 1280;
    if (decoded.width > maxEdge || decoded.height > maxEdge) {
      resized = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxEdge)
          : img.copyResize(decoded, height: maxEdge);
    }

    final jpegBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

    return CapturedPantryImage(
      bytes: jpegBytes,
      mimeType: 'image/jpeg',
      file: File(picked.path),
    );
  }
}
