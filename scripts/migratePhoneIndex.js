/**
 * سكريبت مرة واحدة: بيدور على كل الأعضاء في كل الجيمات، وبيبني
 * gyms/{gymId}/phoneIndex/{phone} = { memberId, name } لكل واحد فيهم.
 *
 * محتاج نفس السيكرت اللي بيتستخدم في الديبلوي: FIREBASE_SERVICE_ACCOUNT
 * (JSON key بتاع service account عنده صلاحية Cloud Datastore User أو
 * Firebase Admin على الأقل).
 *
 * التشغيل:
 *   cd scripts && npm install
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node migratePhoneIndex.js
 *
 * أو عن طريق GitHub Actions - شغّل الووركفلو "Migrate Phone Index" يدوي
 * من تاب Actions (workflow_dispatch)، مرة واحدة بس.
 */

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

async function main() {
  const gymsSnap = await db.collection("gyms").listDocuments();
  let totalMembers = 0;
  let totalIndexed = 0;

  for (const gymRef of gymsSnap) {
    const gymId = gymRef.id;
    const membersSnap = await db.collection(`gyms/${gymId}/members`).get();

    const batch = db.batch();
    let batchCount = 0;

    for (const memberDoc of membersSnap.docs) {
      totalMembers++;
      const data = memberDoc.data();
      const phone = (data.phone || "").trim();
      if (!phone) continue;

      const indexRef = db.doc(`gyms/${gymId}/phoneIndex/${phone}`);
      batch.set(indexRef, { memberId: memberDoc.id, name: data.name || "" });
      batchCount++;
      totalIndexed++;

      // Firestore batch limit 500
      if (batchCount >= 400) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`✓ ${gymId}: ${membersSnap.size} عضو`);
  }

  console.log(`\nتم. إجمالي الأعضاء: ${totalMembers}, تم فهرستهم: ${totalIndexed}`);
}

main().catch((err) => {
  console.error("فشل السكريبت:", err);
  process.exit(1);
});
