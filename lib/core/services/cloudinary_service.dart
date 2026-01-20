import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
  });

  final String cloudName;
  final String uploadPreset;

  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'weather_wardrobe/listings',
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: ${res.statusCode} ${res.body}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final url = (jsonMap['secure_url'] ?? '').toString();

    if (url.isEmpty) throw Exception('Cloudinary did not return secure_url');

    return url;
  }
}
