# Gym Manager - نظام إدارة الجيم

تطبيق Flutter لإدارة الجيمات بـ 3 أدوار: أدمن، موظف استقبال، عضو.
مبني بـ Clean Architecture + Riverpod + Firebase.

## المميزات

- **Auth**: تسجيل دخول منفصل (أدمن/موظف بإيميل، عضو برقم موبايل) مع توجيه تلقائي لكل دور لداشبورده
- **Members**: إضافة/بحث/متابعة الأعضاء وحالة اشتراكهم
- **Subscriptions**: خطط اشتراك + عملية اشتراك atomic (Transaction) بتحدث بيانات العضو وتسجل الدفعة مع بعض
- **Attendance**: تسجيل حضور بمسح QR Code، مع رفض الدخول تلقائياً لو الاشتراك منتهي
- **Classes**: جدول كلاسات + حجز/إلغاء بـ Transaction يمنع الحجز الزيادة عن السعة
- **Payments**: سجل كامل للمدفوعات وإجمالي الإيرادات

## ⚠️ مهم: خطة Firebase المجانية (Spark) وحدودها

Google غيّرت سياسة Firebase في فبراير 2026: **Cloud Storage بقى محتاج خطة Blaze إجبارياً**، و**Cloud Functions** كانت دايماً محتاجة Blaze من الأساس.

يعني على خطتك المجانية الحالية:

| الخدمة | شغالة على Spark المجاني؟ |
|---|---|
| Firestore (قاعدة البيانات) | ✅ شغالة عادي |
| Authentication (تسجيل الدخول) | ✅ شغالة عادي |
| Cloud Messaging (استقبال إشعارات) | ✅ شغالة عادي |
| **صور الأعضاء** | ✅ شغالة - بقت عن طريق **Cloudinary** بدل Firebase Storage (شوف تحت) |
| **Cloud Functions** (إرسال تنبيهات انتهاء الاشتراك تلقائياً) | ❌ لسه محتاجة Blaze |

### صور الأعضاء بقت عن طريق Cloudinary

استبدلنا Firebase Storage بـ **Cloudinary Unsigned Upload** - بيرفع الصورة مباشرة من التطبيق من غير ما يحتاج مفتاح سري أو Backend، وده مجاني في حدوده (25 جيجا تخزين وباند ويدث شهرياً في الخطة المجانية).

الإعداد جاهز ومربوط بالفعل بحساب Cloudinary بتاعك في:
```
lib/core/services/storage_service.dart
```
لو حبيت تغيّر الحساب لاحقاً، غيّر الـ `_cloudName` و `_uploadPreset` هناك بس.

**ملحوظة أمان**: الـ Unsigned Upload Preset بيسمح لأي حد معاه الـ cloud name والـ preset name (اللي هما جوا كود التطبيق نفسه) إنه يرفع صور على حسابك - ده طبيعي وده أصل فكرة الـ unsigned upload، بس لو حبيت تتحكم أكتر ممكن تحط حدود من لوحة تحكم Cloudinary (Settings → Upload → عدّل الـ preset) زي: حجم أقصى للملف، أنواع ملفات مسموحة، أو معدل رفع محدود.

### تنبيهات انتهاء الاشتراك - لسه محتاجة Blaze
مش هتوصل push تلقائي للعضو من غير Cloud Functions، لكن **البديل المجاني موجود بالفعل جوا التطبيق**:
  - الأدمن شايف عدد "الاشتراكات اللي قربت تخلص" في الداشبورد بشكل مباشر كل ما يفتح التطبيق
  - العضو شايف حالة اشتراكه (لون أحمر/أصفر/أخضر) في داشبورده كل ما يفتح التطبيق

لو حبيت الميزة دي شغالة فعلياً بعدين، Blaze pay-as-you-go مش اشتراك ثابت، وباستخدام صغير غالباً مش هتدفع فلوس فعلياً.

## خطوات التشغيل

### ⚠️ 0. الترتيب الصح قبل أي push على الجيت (مهم جداً)

المشروع اللي في الملف ده كود Dart (`lib/`) بس، **مفيش فولدرات `android/` و `ios/`** لسه - دي بتتولد بأمر واحد. لو عملت push كده على طول، الـ CI هيفشل لإن مفيش مشروع Flutter حقيقي أصلاً.

الترتيب الصح بالظبط:

```bash
# 1. افتح Terminal في مجلد المشروع اللي فيه lib/ و pubspec.yaml

# 2. ولّد فولدرات المنصات (android/ios) - ده بيبني هيكل Flutter الحقيقي
#    من غير ما يلمس lib/ أو pubspec.yaml بتاعتنا
flutter create --org com.yourcompany --project-name gym_manager .

# 3. ثبّت الباكدجات
flutter pub get

# 4. اربط بمشروع Firebase حقيقي (هيولّد lib/firebase_options.dart تلقائي)
dart pub global activate flutterfire_cli
flutterfire configure

# 5. جرب تشغل التطبيق محلياً وتأكد إنه شغال قبل أي push
flutter run

# 6. دلوقتي بس اعمل git init/commit/push
git init
git add .
git commit -m "Initial commit - gym manager app"
git remote add origin <رابط الريبو بتاعك>
git push -u origin main
```

### ملف الـ CI (GitHub Actions) جاهز بالفعل

فيه ملف `.github/workflows/build.yml` جاهز، بيبني APK تلقائي مع كل push على main. بس محتاج منك خطوة واحدة الأول: بما إن `lib/firebase_options.dart` و `android/app/google-services.json` بيتستبعدوا من الجيت (فيهم بيانات مشروعك، شوف `.gitignore`)، لازم تحطهم كـ **GitHub Secrets** عشان الـ CI يقدر يبنيهم وقت الـ build:

```bash
# بعد ما تعمل flutterfire configure (خطوة 4 فوق)، حوّل الملفين لـ base64:
base64 -i lib/firebase_options.dart | tr -d '\n' > firebase_options_b64.txt
base64 -i android/app/google-services.json | tr -d '\n' > google_services_b64.txt
```

بعدها من GitHub: Repo Settings → Secrets and variables → Actions → New repository secret، وضيف:
- `FIREBASE_OPTIONS_DART_B64` = محتوى `firebase_options_b64.txt`
- `GOOGLE_SERVICES_JSON_B64` = محتوى `google_services_b64.txt`

بعد كده أي push على main هيبني APK تلقائي وتقدر تنزله من تبويب Actions → آخر run → Artifacts.

### 1. تثبيت الباكدجات
```bash
flutter pub get
```

### 2. ربط المشروع بـ Firebase
لازم يكون عندك Firebase CLI و FlutterFire CLI متثبتين:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
ده هيولّد `firebase_options.dart` تلقائي بمفاتيحك الحقيقية (الملف الموجود دلوقتي مجرد placeholder).

### 3. تفعيل خدمات Firebase المطلوبة
من Firebase Console:
- **Authentication** → فعّل Email/Password
- **Firestore Database** → أنشئ قاعدة بيانات (ابدأ بـ test mode للتجربة، وبعدين ظبط الـ Security Rules)

### 4. إعداد أول أدمن يدوياً
أول مرة، لازم تعمل مستخدم أدمن يدوي من Firebase Console:
1. Authentication → Add User (بإيميل وباسورد)
2. انسخ الـ UID بتاعه
3. Firestore → أنشئ document في collection اسمها `users` بنفس الـ UID، وحط فيه:
```json
{
  "gymId": "default_gym",
  "name": "اسمك",
  "phone": "01xxxxxxxxx",
  "email": "admin@example.com",
  "role": "admin",
  "createdAt": <timestamp>
}
```

بعد كده الأدمن يقدر يضيف موظفين وأعضاء من داخل التطبيق نفسه.

### 5. تشغيل التطبيق
```bash
flutter run
```

## هيكل المشروع

```
lib/
├── core/              # أدوات وثوابت مشتركة (theme, errors, routing..)
├── features/
│   ├── auth/          # تسجيل الدخول والأدوار
│   ├── members/       # إدارة الأعضاء
│   ├── subscriptions/ # خطط الاشتراك
│   ├── attendance/    # الحضور والانصراف (QR)
│   ├── classes/       # الكلاسات والحجز
│   ├── payments/       # المدفوعات
│   └── dashboard/      # الداشبوردات الثلاثة
└── main.dart
```

كل فيتشر مقسم لـ `data` (Firebase implementation) / `domain` (entities + repository interfaces) / `presentation` (Riverpod providers + شاشات).

## Firestore Security Rules

ملف قواعد أمان جاهز وشامل موجود في `firestore.rules` (مش مجرد مثال مبسط زي قبل كده) - بيغطي كل الـ collections بصلاحيات مختلفة لكل دور (أدمن/موظف/عضو)، وبيمنع حذف السجلات التاريخية زي الاشتراكات والحضور.

لتطبيقه:
```bash
firebase deploy --only firestore:rules
```
أو انسخ محتواه يدوياً في Firebase Console → Firestore Database → Rules.

## المتبقي / خطوات تالية مقترحة

- [ ] تعديل/حذف كلاس بعد إنشائه (حالياً بس إضافة)
- [ ] فلترة/بحث في سجل المدفوعات والتقارير بمدى تاريخ مخصص

## اللي اتعمل بالكامل (تحديث نهائي)

**الأساسيات**
- شاشة إضافة عضو جديد (`add_member_screen.dart`) - متصلة بزرار (+) في MembersListScreen
- **تعديل وحذف عضو** - من قائمة (⋮) في شاشة تفاصيل العضو (أدمن وموظف بس)
- **رفع صورة شخصية للعضو** - من نفس شاشة الإضافة/التعديل، بترفع على Cloudinary (Unsigned Upload) وتتعرض في الكارت والتفاصيل - شغالة على الخطة المجانية بالكامل
- شاشة إضافة/تعديل خطة اشتراك (`add_plan_dialog.dart`) - Dialog بوضعين، مع حذف (soft delete)
- شاشة اختيار خطة + اشتراك/تجديد فعلي (`subscribe_dialog.dart`)
- شاشة إضافة كلاس جديد (`add_class_screen.dart`) - بقت بتختار المدرب من قائمة حقيقية بدل كتابة الاسم
- **إدارة المدربين** (`trainers_list_screen.dart`, `add_trainer_dialog.dart`) - سجل مدربين حقيقي مربوط بالكلاسات
- شاشة إضافة موظف (`add_staff_screen.dart`) - بتعمل حساب Firebase Auth حقيقي
- **التقارير المالية** (`reports_screen.dart`) - إيرادات الشهر/السنة الحالية + رسم بياني بسيط لآخر 6 شهور
- **تنبيهات Push** - إعداد كامل من طرفين:
  - **التطبيق**: `notification_service.dart` بيسجل الـ FCM token في Firestore بعد كل تسجيل دخول، وبيمسحه عند تسجيل الخروج
  - **السيرفر**: `functions/index.js` فيه Cloud Function مجدولة (يومياً 9 الصبح بتوقيت القاهرة) بتدور على الأعضاء اللي اشتراكهم هيخلص خلال 3 أيام وتبعتلهم تنبيه، وتبعت تنبيه مجمع للأدمن/الموظفين
- **`firestore.rules`** كامل - صلاحيات دقيقة لكل دور على كل collection

## نشر الـ Cloud Function (لتفعيل تنبيهات انتهاء الاشتراك فعلياً)

```bash
firebase login
firebase use --add   # اختار مشروعك
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules
```

ملحوظة: نشر Cloud Functions محتاج خطة Firebase مدفوعة (Blaze) - Firestore والـ Auth نفسهم مجانيين، بس Functions بتحتاج Blaze حتى لو الاستهلاك تحت الحد المجاني.
"# gym" 
