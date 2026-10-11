import 'package:gym_manager/core/network/document_store.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/data_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../models/member_model.dart';

class MemberRepositoryImpl implements MemberRepository {
  final DocumentStore _store;
  final String gymId;

  MemberRepositoryImpl({required this.gymId, DocumentStore? store})
      : _store = store ?? DocumentStore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _store.collection(DataPaths.members(gymId));

  CollectionReference<Map<String, dynamic>> get _phoneIndex =>
      _store.collection('gyms/$gymId/phoneIndex');

  @override
  Stream<List<Member>> watchMembers() {
    return _collection.orderBy('joinDate', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => MemberModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Stream<Member?> watchMemberById(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MemberModel.fromMap(doc.data()!, doc.id);
    });
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
      final row = await _store.command('member-save', {'gymId': gymId, 'data': MemberModel.fromEntity(member).toMap()}) as Map<String, dynamic>;
      return Right(MemberModel.fromMap(Map<String, dynamic>.from(row['data'] as Map), row['id'] as String));
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }

  @override
  Future<Either<Failure, void>> updateMember(Member member) async {
    try {
      await _store.command('member-save', {'gymId': gymId, 'memberId': member.id, 'data': MemberModel.fromEntity(member).toMap()});
      return const Right(null);
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }

  @override
  Future<Either<Failure, void>> deleteMember(String id) async {
    try {
      await _store.command('member-delete', {'gymId': gymId, 'memberId': id});
      return const Right(null);
    } catch (error) { return Left(ServerFailure(error.toString())); }
  }

  @override
  Future<Either<Failure, List<Member>>> searchMembers(String query) async {
    try {
      // بحث بالاسم من خلال API
      // الفلاتر تتطبق على السيرفر داخل بيانات الجيم الحالي
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

  @override
  Future<Either<Failure, bool>> isPhoneTaken(String phone, {String? excludeMemberId}) async {
    try {
      if (phone.isEmpty) return const Right(false);
      final doc = await _phoneIndex.doc(phone).get();
      if (!doc.exists) return const Right(false);
      final ownerId = doc.data()?['memberId'] as String?;
      // لو الرقم موجود بس بتاع نفس العضو اللي بنعدله، ده مش تكرار
      if (excludeMemberId != null && ownerId == excludeMemberId) return const Right(false);
      return const Right(true);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

