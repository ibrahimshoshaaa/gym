/**
 * Cloud Function مجدولة - بتشتغل مرة كل يوم، بتدور على كل الأعضاء
 * اللي اشتراكهم هيخلص خلال 3 أيام، وتبعتلهم تنبيه FCM.
 *
 * الأدمن والموظفين هيستقبلوا تنبيه منفصل يلخصلهم عدد الأعضاء
 * اللي محتاجين يجددوا النهاردة.
 *
 * النشر:
 *   cd functions && npm install
 *   firebase deploy --only functions
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Callable function - بتُستدعى بعد ما العميل يعمل signInAnonymously().
 * بتدور على العضو برقم موبايله في members، وتربط الحساب (users/{uid})
 * بسجله - أول مرة بس. الاستخدام لـ Admin SDK هنا مقصود: rules الـ
 * Firestore بتشترط إن يوزر يبقى ليه users doc موجود عشان يقرأ members
 * (belongsToGym) - يعني عضو بيدخل أول مرة مش هيقدر يعمل البحث ده من
 * العميل مباشرة أصلاً. الفنكشن دي بتحل المشكلة من غير ما نفتح قواعد
 * الأمان لقراءة members قبل ما يتربط الحساب.
 */
exports.linkMemberLogin = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "لازم تسجل دخول الأول");
  }

  const phone = (request.data?.phone || "").trim();
  const gymId = (request.data?.gymId || "").trim();
  if (!phone || !gymId) {
    throw new HttpsError("invalid-argument", "رقم الموبايل ومعرّف الجيم مطلوبين");
  }

  const memberQuery = await db
    .collection(`gyms/${gymId}/members`)
    .where("phone", "==", phone)
    .limit(1)
    .get();

  if (memberQuery.empty) {
    throw new HttpsError("not-found", "لا يوجد عضو بهذا الرقم في هذا الجيم");
  }

  const memberDoc = memberQuery.docs[0];
  const memberId = memberDoc.id;
  const memberName = memberDoc.data().name || "";

  const usersRef = db.collection("users").doc(uid);
  const userSnap = await usersRef.get();

  if (userSnap.exists) {
    const existing = userSnap.data();
    // الجهاز ده لسه فاتح جلسة عضو تاني (تابلت استقبال مشترك مثلاً)
    if (existing.phone !== phone || existing.gymId !== gymId) {
      throw new HttpsError(
        "failed-precondition",
        "الجهاز ده لسه فاتح جلسة عضو تاني. سجل خروج الأول وبعدين حاول تاني"
      );
    }
    // موجود بالفعل ومطابق - مفيش حاجة نعملها، العميل هيقرأ الدوك عادي
    return { linked: true };
  }

  await usersRef.set({
    gymId,
    name: memberName,
    phone,
    email: null,
    role: "member",
    memberId,
    createdAt: Timestamp.now(),
  });
  // بنرجع إشارة نجاح بس - العميل هيقرأ الدوك اللي اتعمل عادي من
  // users/{uid} (مسموح له لأن uid == request.auth.uid دلوقتي)
  return { linked: true };
});

const EXPIRY_THRESHOLD_DAYS = 3;

exports.checkExpiringSubscriptions = onSchedule(
  {
    schedule: "every day 09:00",
    timeZone: "Africa/Cairo",
  },
  async () => {
    const gymsSnap = await db.collection("gyms").listDocuments();

    for (const gymRef of gymsSnap) {
      await processGym(gymRef.id);
    }
  }
);

async function processGym(gymId) {
  const now = new Date();
  const threshold = new Date(now);
  threshold.setDate(threshold.getDate() + EXPIRY_THRESHOLD_DAYS);

  const membersSnap = await db
    .collection(`gyms/${gymId}/members`)
    .where("subscriptionEnd", ">=", Timestamp.fromDate(now))
    .where("subscriptionEnd", "<=", Timestamp.fromDate(threshold))
    .get();

  if (membersSnap.empty) return;

  const expiringMembers = [];

  for (const memberDoc of membersSnap.docs) {
    const member = memberDoc.data();
    expiringMembers.push({ id: memberDoc.id, name: member.name });

    // نبعت تنبيه للعضو نفسه لو ليه حساب مرتبط (users where memberId == doc.id)
    const userQuery = await db
      .collection("users")
      .where("memberId", "==", memberDoc.id)
      .limit(1)
      .get();

    if (!userQuery.empty) {
      const token = userQuery.docs[0].data().fcmToken;
      if (token) {
        await sendNotification(token, "اشتراكك قرب يخلص ⏰", `اشتراكك في الجيم هيخلص قريب، جدده دلوقتي عشان تكمل تمرينك من غير قطع.`);
      }
    }
  }

  // تنبيه مجمع للأدمن والموظفين بالجيم ده
  if (expiringMembers.length > 0) {
    const staffQuery = await db
      .collection("users")
      .where("gymId", "==", gymId)
      .where("role", "in", ["admin", "staff"])
      .get();

    const body = `${expiringMembers.length} عضو اشتراكهم هيخلص خلال ${EXPIRY_THRESHOLD_DAYS} أيام`;

    for (const staffDoc of staffQuery.docs) {
      const token = staffDoc.data().fcmToken;
      if (token) {
        await sendNotification(token, "اشتراكات قربت تخلص", body);
      }
    }
  }
}

async function sendNotification(token, title, body) {
  try {
    await messaging.send({
      token,
      notification: { title, body },
    });
  } catch (err) {
    // الـ token ممكن يكون قديم/غير صالح (مثلاً المستخدم مسح التطبيق) - نتجاهل ونكمل
    console.error("فشل إرسال الإشعار:", err.message);
  }
}