import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/member.dart';
import '../providers/members_provider.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  /// لو اتبعت member، الشاشة هتشتغل في وضع التعديل بدل الإضافة
  final Member? member;

  const AddMemberScreen({super.key, this.member});

  bool get isEditMode => member != null;

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  File? _pickedPhoto;
  bool _isLoading = false;
  bool _photoUploadFailed = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _notesController = TextEditingController(text: widget.member?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _pickedPhoto = File(picked.path));
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final repo = ref.read(memberRepositoryProvider);
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final gymId = ref.read(currentUserProvider)?.gymId ?? 'default_gym';

    // في وضع الإضافة، لازم نحفظ العضو الأول عشان ناخد الـ id، وبعدين نرفع الصورة
    // ونحدث السجل بالرابط (الصورة اسمها بمعرف العضو نفسه)
    String? photoUrl = widget.member?.photoUrl;

    final result = widget.isEditMode
        ? await _saveEdit(repo, gymId, notes)
        : await _saveNew(repo, gymId, notes);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode ? 'تم تعديل بيانات العضو ✅' : 'تم إضافة العضو بنجاح ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        if (_photoUploadFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ملحوظة: الصورة متترفعتش (تأكد من اتصال الإنترنت وحاول تاني من التعديل)'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
          );
        }
        Navigator.pop(context);
      },
    );
  }

  Future<dynamic> _saveNew(dynamic repo, String gymId, String? notes) async {
    final addResult = await repo.addMember(Member(
      id: '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      joinDate: DateTime.now(),
      status: MemberStatus.expired,
      notes: notes,
    ));

    return addResult.fold((f) => addResult, (newMember) async {
      if (_pickedPhoto == null) return addResult;
      // رفعنا الصورة بعد ما عرفنا الـ id بتاع العضو
      // لو فشل الرفع (مثلاً Storage محتاج خطة Blaze) منوقفش العملية -
      // العضو بيتحفظ عادي من غير صورة، ونبلغ المستخدم بس
      try {
        final url = await ref
            .read(storageServiceProvider)
            .uploadMemberPhoto(gymId: gymId, memberId: newMember.id, file: _pickedPhoto!);
        return repo.updateMember(Member(
          id: newMember.id,
          name: newMember.name,
          phone: newMember.phone,
          joinDate: newMember.joinDate,
          status: newMember.status,
          photoUrl: url,
          notes: newMember.notes,
        ));
      } catch (_) {
        _photoUploadFailed = true;
        return addResult;
      }
    });
  }

  Future<dynamic> _saveEdit(dynamic repo, String gymId, String? notes) async {
    String? photoUrl = widget.member!.photoUrl;
    if (_pickedPhoto != null) {
      try {
        photoUrl = await ref
            .read(storageServiceProvider)
            .uploadMemberPhoto(gymId: gymId, memberId: widget.member!.id, file: _pickedPhoto!);
      } catch (_) {
        _photoUploadFailed = true;
      }
    }

    return repo.updateMember(Member(
      id: widget.member!.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      joinDate: widget.member!.joinDate,
      status: widget.member!.status,
      photoUrl: photoUrl,
      currentPlanId: widget.member!.currentPlanId,
      currentSubscriptionId: widget.member!.currentSubscriptionId,
      subscriptionEnd: widget.member!.subscriptionEnd,
      notes: notes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? 'تعديل بيانات العضو' : 'إضافة عضو جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: _pickedPhoto != null
                            ? FileImage(_pickedPhoto!)
                            : (widget.member?.photoUrl != null
                                ? NetworkImage(widget.member!.photoUrl!)
                                : null) as ImageProvider?,
                        child: _pickedPhoto == null && widget.member?.photoUrl == null
                            ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) => Validators.required(v, 'الاسم'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditMode ? 'حفظ التعديلات' : 'حفظ'),
              ),
              if (!widget.isEditMode) ...[
                const SizedBox(height: 8),
                const Text(
                  'ملحوظة: العضو الجديد بيتضاف بدون اشتراك. اعمله اشتراك من صفحة تفاصيله بعد الحفظ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
