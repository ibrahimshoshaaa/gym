/// مسارات الـ Firestore الخاصة بكل الفيتشرز
/// النظام مبني multi-tenant (كل جيم ليه gymId خاص بيه)
/// عشان نقدر نستخدم نفس النظام لأكتر من جيم مستقبلاً لو حبينا
class FirestorePaths {
  FirestorePaths._();

  static const String gyms = 'gyms';

  static String members(String gymId) => 'gyms/$gymId/members';
  static String plans(String gymId) => 'gyms/$gymId/plans';
  static String subscriptions(String gymId) => 'gyms/$gymId/subscriptions';
  static String attendance(String gymId) => 'gyms/$gymId/attendance';
  static String classes(String gymId) => 'gyms/$gymId/classes';
  static String trainers(String gymId) => 'gyms/$gymId/trainers';
  static String staff(String gymId) => 'gyms/$gymId/staff';
  static String payments(String gymId) => 'gyms/$gymId/payments';
  static String debts(String gymId) => 'gyms/$gymId/debts';

  static String member(String gymId, String memberId) =>
      '${members(gymId)}/$memberId';
  static String subscription(String gymId, String subId) =>
      '${subscriptions(gymId)}/$subId';
  static String classDoc(String gymId, String classId) =>
      '${classes(gymId)}/$classId';
}
