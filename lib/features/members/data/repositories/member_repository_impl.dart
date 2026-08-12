import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../models/member_model.dart';

class MemberRepositoryImpl implements MemberRepository {
  final FirebaseFirestore _firestore;
  final String gymId;

  MemberRepositoryImpl({required this.gymId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.members(gymId));

  CollectionReference<Map<String, dynamic>> get _phoneIndex =>
      _firestore.collection('gyms/$gymId/phoneIndex');

  @override
  Stream<List<Member>> watchMembers() {
    return _collection.orderBy('joinDate', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => MemberModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Future<Either<Failure, Member>> getMemberById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return const Left(NotFoundFailure('العضو غير موجود'));
      return Right(MemberModel.fromMap(doc.data()!, doc.id));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Member>> addMember(Member member) async {
    try {
      final model = MemberModel.fromEntity(member);
      final docRef = await _collection.add(model.toMap());
      if (member.phone.isNotEmpty) {
        await _phoneIndex.doc(member.phone).set({
          'memberId': docRef.id,
          'name': member.name,
        });
      }
      return Right(MemberModel.fromMap(model.toMap(), docRef.id));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateMember(Member member) async {
    try {
      final model = MemberModel.fromEntity(member);
      final oldSnap = await _collection.doc(member.id).get();
      final oldPhone = oldSnap.data()?['phone'] as String?;

      await _collection.doc(member.id).update(model.toMap());

      // لو الرقم اتغيّر، امسح الفهرس القديم واكتب الجديد
      if (oldPhone != null && oldPhone != member.phone && oldPhone.isNotEmpty) {
        await _phoneIndex.doc(oldPhone).delete();
      }
      if (member.phone.isNotEmpty) {
        await _phoneIndex.doc(member.phone).set({
          'memberId': member.id,
          'name': member.name,
        });
      }
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteMember(String id) async {
    try {
      final snap = await _collection.doc(id).get();
      final phone = snap.data()?['phone'] as String?;
      await _collection.doc(id).delete();
      if (phone != null && phone.isNotEmpty) {
        await _phoneIndex.doc(phone).delete();
      }
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Member>>> searchMembers(String query) async {
    try {
      // بحث بسيط بالاسم (Firestore مش بيدعم full-text search أصلاً)
      // للبحث المتقدم لاحقاً ممكن تستخدم Algolia أو Typesense
      final snap = await _collection
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();
      return Right(snap.docs.map((d) => MemberModel.fromMap(d.data(), d.id)).toList());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
