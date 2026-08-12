import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// خدمة رفع الصور - بتستخدم Cloudinary (Unsigned Upload) بدل Firebase Storage
/// عشان تشتغل على خطة Firebase المجانية (Spark) من غير الحاجة لترقية Blaze.
///
/// الإعداد: من لوحة تحكم Cloudinary -> Settings -> Upload -> Upload presets
/// أنشئ preset بوضع "Unsigned" وحط اسمه واسم الـ Cloud بتاعك تحت.
class StorageService {
  // بيانات حساب الـ Cloudinary بتاع إبراهيم
  static const String _cloudName = 'dzbvceezc';
  static const String _uploadPreset = 'Workshop';

  Future<String> uploadMemberPhoto({
    required String gymId,
    required String memberId,
    required File file,
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      // public_id ثابت بمعرف العضو، عشان لو رفعنا صورة جديدة تستبدل القديمة
      // بدل ما تتراكم صور قديمة من غير داعي على الحساب
      ..fields['public_id'] = 'gym_manager/$gymId/members/$memberId'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception('فشل رفع الصورة على Cloudinary: $responseBody');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  /// ملحوظة: الحذف بيحتاج API موقّع (signed) بمفتاح سري، ومينفعش من التطبيق
  /// مباشرة بأمان مع Unsigned Upload. الصورة القديمة هتتستبدل تلقائياً
  /// عند رفع صورة جديدة بنفس public_id، فمش محتاجين حذف صريح فعلياً.
  Future<void> deleteMemberPhoto({required String gymId, required String memberId}) async {
    // no-op بالتصميم - شوف الملحوظة فوق
  }
}
