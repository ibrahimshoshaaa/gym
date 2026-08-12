/**
 * نفس منطق checkExpiringSubscriptions اللي كان في functions/index.js،
 * بس بيتشغل كـ سكريبت عادي بـ Admin SDK (مش Cloud Function مجدولة)
 * عشان محتاجش Blaze plan. بيتشغل يوميًا عن طريق GitHub Actions cron
 * (شوف .github/workflows/scheduled-notifications.yml).
 */

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const messaging = getMessaging();

const EXPIRY_THRESHOLD_DAYS = 3;

async function sendNotification(token, title, body) {
  try {
    await messaging.send({ token, notification: { title, body } });
  } catch (err) {
    console.error("فشل إرسال الإشعار:", err.message);
  }
}

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

    const userQuery = await db
      .collection("users")
      .where("memberId", "==", memberDoc.id)
      .limit(1)
      .get();

    if (!userQuery.empty) {
      const token = userQuery.docs[0].data().fcmToken;
      if (token) {
        await sendNotification(
          token,
          "اشتراكك قرب يخلص ⏰",
          "اشتراكك في الجيم هيخلص قريب، جدده دلوقتي عشان تكمل تمرينك من غير قطع."
        );
      }
    }
  }

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

  console.log(`${gymId}: ${expiringMembers.length} عضو قرب اشتراكه يخلص`);
}

async function main() {
  const gymsSnap = await db.collection("gyms").listDocuments();
  for (const gymRef of gymsSnap) {
    await processGym(gymRef.id);
  }
}

main().catch((err) => {
  console.error("فشل السكريبت:", err);
  process.exit(1);
});
