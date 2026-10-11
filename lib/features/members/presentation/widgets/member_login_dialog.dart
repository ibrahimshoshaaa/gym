import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemberLoginDialog extends StatelessWidget {
  final String gymId;
  final String phone;
  final String password;

  const MemberLoginDialog({super.key, required this.gymId, required this.phone, required this.password});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('حساب العضو جاهز ✓'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(context, 'كود الجيم', gymId),
          _field(context, 'رقم الموبايل', phone),
          _field(context, 'كلمة المرور الأولى', password),
          const SizedBox(height: 8),
          Text(password == phone
              ? 'كلمة المرور هي نفس رقم الموبايل. العضو لازم يختار كلمة جديدة أول ما يسجّل دخول.'
              : 'العضو لازم يغيّر كلمة المرور المؤقتة أول ما يسجّل دخول.'),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: 'بيانات دخول Golden Gym\nكود الجيم: $gymId\nالموبايل: $phone\nكلمة المرور الأولى: $password\nغيّر كلمة المرور أول ما تدخل.'));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ بيانات الدخول')));
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('نسخ البيانات'),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تم')),
      ],
    );
  }

  Widget _field(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      SelectableText(value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    ]),
  );
}
