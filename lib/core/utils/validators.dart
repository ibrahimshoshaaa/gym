class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الموبايل مطلوب';
    final regex = RegExp(r'^01[0125][0-9]{8}$');
    if (!regex.hasMatch(value.trim())) {
      return 'رقم موبايل غير صحيح';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'بريد إلكتروني غير صحيح';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'القيمة']) {
    if (value == null || value.trim().isEmpty) return '$fieldName مطلوبة';
    final n = num.tryParse(value.trim());
    if (n == null || n <= 0) return '$fieldName يجب أن تكون رقم أكبر من صفر';
    return null;
  }
}
